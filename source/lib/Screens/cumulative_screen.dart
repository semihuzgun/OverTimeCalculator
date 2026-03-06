import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class CumulativeScreen extends StatefulWidget {
  const CumulativeScreen({super.key});

  @override
  State<CumulativeScreen> createState() => _CumulativeScreenState();
}

class _CumulativeScreenState extends State<CumulativeScreen> {
  final _controllers = <int, TextEditingController>{};
  bool _loading = true;
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    for (var m = 1; m <= 12; m++) {
      _controllers[m] = TextEditingController();
    }
    _loadValues();
  }

  Future<void> _loadValues() async {
    setState(() => _loading = true);
    final values = await StorageService.getMonthlyValues(_year);
    for (var m = 1; m <= 12; m++) {
      final v = values[m] ?? 0;
      _controllers[m]!.text = v > 0 ? v.toStringAsFixed(2) : '';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveAll() async {
    final values = <int, double>{};
    for (var m = 1; m <= 12; m++) {
      final v = double.tryParse(_controllers[m]!.text.replaceAll(',', '.')) ?? 0;
      values[m] = v;
    }
    await StorageService.saveMonthlyValues(_year, values);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brüt ücretler kaydedildi')),
      );
    }
  }

  double _getTotal() {
    var t = 0.0;
    for (var m = 1; m <= 12; m++) {
      t += double.tryParse(_controllers[m]!.text.replaceAll(',', '.')) ?? 0;
    }
    return t;
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kümülatif Yönetimi'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _saveAll,
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$_year Yılı Aylık Brüt Ücretler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(12, (i) {
                    final month = i + 1;
                    final label = StorageService.monthLabel(_year, month);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[month],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: label,
                          suffixText: '₺',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(
                    'Yıl Başı Kümülatif Toplam',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        currency.format(_getTotal()),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saveAll,
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Önceki ayların brüt ücretini e-devletten SGK hizmet dökümünden bulabilirsiniz.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
