import 'package:flutter/material.dart';
import '../services/payroll_calculator.dart';
import '../services/storage_service.dart';
import 'cumulative_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadLastInputs();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // TEST ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  Future<void> _loadLastInputs() async {
    final cumulative = await StorageService.getCumulativeTotal();
    if (mounted && cumulative > 0) {
      _cumulativeController.text = cumulative.toStringAsFixed(0);
    }
    final last = await StorageService.loadLastInputs();
    if (mounted && last != null) {
      final g = last['gross'] ?? 0;
      if (g > 0) _grossController.text = g.toStringAsFixed(0);
      _hours1Controller.text = _formatSaved(last['hours1']);
      _rate1Controller.text = _formatSaved(last['rate1'], defaultVal: 150);
      _hours2Controller.text = _formatSaved(last['hours2']);
      _rate2Controller.text = _formatSaved(last['rate2'], defaultVal: 200);
    }
  }

  String _formatSaved(double? v, {double? defaultVal}) {
    if (v == null) return defaultVal?.toStringAsFixed(0) ?? '';
    return v == v.toInt() ? v.toInt().toString() : v.toString();
  }

  Future<void> _loadCumulative() async {
    final total = await StorageService.getCumulativeTotal();
    if (mounted && total > 0) {
      _cumulativeController.text = total.toStringAsFixed(0);
    }
  }

  void _showSaveToCumulativeDialog() {
    double gross = double.tryParse(_grossController.text) ?? 0;
    if (gross <= 0 || grossOvertimeResult == null) return;
    final totalBrut = gross + grossOvertimeResult!;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final year = DateTime.now().year;

    int selectedMonth = DateTime.now().month;
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
                value: selectedMonth,
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
                    setDialogState(() => selectedMonth = v);
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
                  selectedMonth,
                  totalBrut,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${StorageService.monthLabel(year, selectedMonth)} kaydedildi: ${currency.format(totalBrut)}',
                      ),
                    ),
                  );
                  _loadCumulative();
                }
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
    double cumulative = double.tryParse(_cumulativeController.text) ?? 0;

    double h1 = double.tryParse(_hours1Controller.text) ?? 0;
    double r1 = double.tryParse(_rate1Controller.text) ?? 150;

    double h2 = double.tryParse(_hours2Controller.text) ?? 0;
    double r2 = double.tryParse(_rate2Controller.text) ?? 200;

    List<Map<String, double>> overtimeList = [
      {"hours": h1, "rate": r1},
      {"hours": h2, "rate": r2},
    ];

    double net = PayrollCalculator.calculateNet(
      grossSalary: gross,
      overtimeList: overtimeList,
      cumulativeBase: cumulative,
    );

    double overTime = PayrollCalculator.calculateOvertimeDynamic(
      gross,
      overtimeList,
    );

    setState(() {
      netResult = net;
      grossOvertimeResult = overTime;
    });

    // Son girdileri kaydet
    StorageService.saveLastInputs(
      gross: gross,
      cumulative: cumulative,
      hours1: h1,
      rate1: r1,
      hours2: h2,
      rate2: r2,
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    String monthName = DateFormat.MMMM('tr_TR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text("Fazla Mesai Hesaplama")),
      bottomNavigationBar: _isBannerReady
    ?  Container(
        padding: const EdgeInsets.only(bottom: 12, top: 6),
        color: Colors.white,
        child: SizedBox(
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
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
              title: const Text('Hesaplama'),
              onTap: () => Navigator.pop(context),
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
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInput("Aylık Brüt Maaş", _grossController),

            const SizedBox(height: 12),

            _buildOvertimeRow(_hours1Controller, _rate1Controller),

            const SizedBox(height: 12),

            _buildOvertimeRow(_hours2Controller, _rate2Controller),

            const SizedBox(height: 12),

            _buildInput("Yıl Başı Kümülatif Brüt", _cumulativeController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text("Hesapla"),
            ),

            const SizedBox(height: 30),

            if (netResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (grossOvertimeResult != null) ...[
                        Text(
                          "$monthName Ayı Fazla Mesai Brüt Ücreti",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currency.format(grossOvertimeResult),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                      Text(
                        "$monthName Ayı Tahmini Net Ücret",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currency.format(netResult),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (grossOvertimeResult != null)
                        TextButton.icon(
                          onPressed: _showSaveToCumulativeDialog,
                          icon: const Icon(Icons.save),
                          label: const Text('Bu ayı kümülatife kaydet'),
                        ),
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
