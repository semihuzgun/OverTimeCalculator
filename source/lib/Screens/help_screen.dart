import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Kılavuzu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, 'Uygulama Nasıl Kullanılır?'),
            const SizedBox(height: 16),
            
            _buildGuideCard(
              context,
              icon: Icons.payments_outlined,
              title: '1. Brüt Maaş Girişi',
              description: 'Bordronuzda yer alan "Aylık Brüt" tutarını girin. Bu tutar mesailer hariç olan çıplak maaşınızdır.',
            ),
            
            _buildGuideCard(
              context,
              icon: Icons.more_time,
              title: '2. Mesai Saatleri ve Oranları',
              description: 'Yaptığınız mesai saatini ve oranını girin. Hafta içi %150, hafta sonu/bayram %200 girilmelidir.',
            ),

            _buildGuideCard(
              context,
              icon: Icons.calendar_month,
              title: '3. Ay Seçimi ve Vergi Dilimi',
              description: 'Hesaplamak istediğiniz ayı seçin. Uygulama seçilen aya göre vergi diliminizi (kümülatif matrahı) belirler.',
            ),

            const SizedBox(height: 8),
            _buildHeader(context, 'Kümülatif ve Kayıt Yönetimi'),
            const SizedBox(height: 16),

            _buildGuideCard(
              context,
              icon: Icons.auto_graph,
              title: 'Geçmiş Ay Bilgileri',
              description: 'Uygulamayı kullanmaya yıl ortasında başladıysanız, "Kümülatif Yönetimi" menüsünden önceki ayların brütlerini manuel girerek vergi dilimini senkronize edebilirsiniz.',
            ),

            _buildGuideCard(
              context,
              icon: Icons.save_as,
              title: 'Kümülatife Kaydetme',
              description: 'Hesaplama sonrası "Kümülatife Kaydet" butonu ile o ayın verisini saklayabilir veya güncelleyebilirsiniz.',
            ),

            const SizedBox(height: 24),
            
            // YENİ EKLENEN: E-DEVLET VE SGK İPUCU KUTUSU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kümülatif Bilgisine Nasıl Ulaşılır?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Önceki aylara ait kümülatif brüt bilgilerini e-Devlet üzerinden "SGK Hizmet Dökümü" belgesini alarak, ilgili aylardaki "PEK" (Prime Esas Kazanç) tutarlarından bulabilirsiniz.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Yasal Uyarı Notu
            const Text(
              'Not: Bu uygulama 2026 yasal parametrelerine göre çalışır ve bilgilendirme amaçlıdır. Kesin sonuçlar için resmi bordronuzu kontrol ediniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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