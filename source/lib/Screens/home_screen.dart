import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../Services/ads_manager.dart';
import '../Services/payroll_calculator.dart';
import '../Services/storage_service.dart';
import 'cumulative_screen.dart';
import 'help_screen.dart';
import 'hourly_wage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _grossController = TextEditingController();
  final _cumulativeController = TextEditingController();

  final _hours1Controller = TextEditingController();
  final _rate1Controller = TextEditingController(text: "150");

  final _hours2Controller = TextEditingController();
  final _rate2Controller = TextEditingController(text: "200");

  double? netResult;
  double? grossOvertimeResult;
  double? totalGrossResult;

  late final BannerAd _bannerAd;
  bool _bannerCreated = false;
  bool _isBannerReady = false;

  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadLastInputs();
    _loadBanner();
  }

  void _loadBanner() {
    if (!AdsManager.isEnabled) {
      print('[Ads] AdsManager disabled, skipping banner load.');
      return;
    }

    _bannerCreated = true;
    _bannerAd = BannerAd(
      adUnitId: AdsManager.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('[Ads] Banner loaded successfully.');
          if (!mounted) return;
          setState(() => _isBannerReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          print('[Ads] Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  Future<void> _loadLastInputs() async {
    // İlk açılışta seçili aya göre kümülatifi yükle
    await _loadCumulative();

    final last = await StorageService.loadLastInputs();
    if (!mounted || last == null) return;

    final g = last['gross'] ?? 0;
    if (g > 0) _grossController.text = g.toStringAsFixed(0);

    _hours1Controller.text = _formatSaved(last['hours1']);
    _rate1Controller.text = _formatSaved(last['rate1'], defaultVal: 150);

    _hours2Controller.text = _formatSaved(last['hours2']);
    _rate2Controller.text = _formatSaved(last['rate2'], defaultVal: 200);
  }

  String _formatSaved(double? v, {double? defaultVal}) {
    if (v == null) return defaultVal?.toStringAsFixed(0) ?? '';
    return v == v.toInt() ? v.toInt().toString() : v.toString();
  }

  Future<void> _loadCumulative() async {
    final total =
        await StorageService.getCumulativeTotal(untilMonth: selectedMonth);
    if (!mounted) return;
    setState(() {
      _cumulativeController.text = total > 0 ? total.toStringAsFixed(2) : '0';
    });
  }

  void _showSaveToCumulativeDialog() {
    double gross = double.tryParse(_grossController.text) ?? 0;
    if (gross <= 0 || grossOvertimeResult == null) return;

    final totalBrut = gross + grossOvertimeResult!;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final year = DateTime.now().year;

    int dialogSelectedMonth = selectedMonth;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kümülatife Kaydet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tutar: ${currency.format(totalBrut)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Kaydedilecek ayı seçin:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: dialogSelectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Ay',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (i) {
                  final m = i + 1;
                  return DropdownMenuItem(
                    value: m,
                    child: Text(StorageService.monthLabel(year, m)),
                  );
                }),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => dialogSelectedMonth = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await StorageService.setMonthValue(
                  year,
                  dialogSelectedMonth,
                  totalBrut,
                );
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${StorageService.monthLabel(year, dialogSelectedMonth)} kaydedildi: ${currency.format(totalBrut)}',
                    ),
                  ),
                );
                _loadCumulative();
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 50)),
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _calculate() {
    double gross = double.tryParse(_grossController.text) ?? 0;
    double cumulativeFromUI = double.tryParse(_cumulativeController.text) ?? 0;

    double h1 = double.tryParse(_hours1Controller.text) ?? 0;
    double r1 = double.tryParse(_rate1Controller.text) ?? 150;

    double h2 = double.tryParse(_hours2Controller.text) ?? 0;
    double r2 = double.tryParse(_rate2Controller.text) ?? 200;

     List<Map<String, double>> overtimeList = <Map<String, double>>[
      {"hours": h1, "rate": r1},
      {"hours": h2, "rate": r2},
    ];

    double net = PayrollCalculator.calculateNet(
      grossSalary: gross,
      overtimeList: overtimeList,
      month: selectedMonth,
      cumulativeGross: cumulativeFromUI,
    );

    double overTime =
        PayrollCalculator.calculateOvertimeDynamic(gross, overtimeList);

    setState(() {
      netResult = net;
      grossOvertimeResult = overTime;
      totalGrossResult = gross + overTime;
    });

    StorageService.saveLastInputs(
      gross: gross,
      cumulative: cumulativeFromUI,
      hours1: h1,
      rate1: r1,
      hours2: h2,
      rate2: r2,
    );
  }

  @override
  void dispose() {
    if (AdsManager.isEnabled && _bannerCreated) {
      _bannerAd.dispose();
    }
    _grossController.dispose();
    _cumulativeController.dispose();
    _hours1Controller.dispose();
    _rate1Controller.dispose();
    _hours2Controller.dispose();
    _rate2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    String displayMonthName =
        DateFormat.MMMM('tr_TR').format(DateTime(2026, selectedMonth));

    return Scaffold(
      appBar: AppBar(title: const Text("Aylık Brüt Ücret ile Hesaplama")),
      bottomNavigationBar: _isBannerReady
          ? Container(
              padding: const EdgeInsets.only(bottom: 12, top: 6),
              color: Colors.white,
              child: SizedBox(
                height: _bannerAd.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),
            )
          : null,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2E86DE)),
              child: Text(
                'Menü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('Hesaplama (Aylık Brüt)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Hesaplama(Saatlik Brüt)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HourlyWageScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Kümülatif Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CumulativeScreen(),
                  ),
                ).then((_) => _loadCumulative());
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_mark),
              title: const Text('Yardım'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInput("Aylık Brüt Maaş", _grossController),
            const SizedBox(height: 10),
            _buildOvertimeRow(_hours1Controller, _rate1Controller),
            const SizedBox(height: 10),
            _buildOvertimeRow(_hours2Controller, _rate2Controller),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: InputDecoration(
                labelText: "Hesaplanacak Ay",
                prefixIcon: const Icon(Icons.calendar_month),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: List.generate(12, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    DateFormat.MMMM('tr_TR').format(DateTime(2026, i + 1)),
                  ),
                );
              }),
              onChanged: (val) async {
                if (val != null) {
                  setState(() => selectedMonth = val);
                  await _loadCumulative();
                }
              },
            ),
            const SizedBox(height: 12),
            _buildInput("Yıl Başı Kümülatif Brüt", _cumulativeController),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text("Hesapla"),
            ),
            const SizedBox(height: 10),
            if (netResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (grossOvertimeResult != null && totalGrossResult != null) ...[
                        Text(
                          "$displayMonthName Ayı Fazla Mesai Brüt Ücreti",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currency.format(grossOvertimeResult),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "$displayMonthName Ayı Toplam Brüt Ücreti",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currency.format(totalGrossResult),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                      Text(
                        "$displayMonthName Ayı Tahmini Net Ücret",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currency.format(netResult),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (grossOvertimeResult != null)
                        TextButton.icon(
                          onPressed: _showSaveToCumulativeDialog,
                          icon: const Icon(Icons.save),
                          label: const Text('Bu ayı kümülatife kaydet'),
                        ),
                      const Divider(),
                      const Text(
                        "Bu hesaplama bilgilendirme amaçlıdır.\n"
                        "Vergi dilimi ve kesintiler kullanıcı beyanına göre tahmini hesaplanmıştır.\n"
                        "Resmi bordro yerine geçmez ve kesinlik içermez.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOvertimeRow(
    TextEditingController hourController,
    TextEditingController rateController,
  ) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildInput("Mesai Saati", hourController)),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _buildInput("Oran %", rateController)),
      ],
    );
  }
}