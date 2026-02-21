class PayrollCalculator {
  // ---- 2026 YASAL SABİTLER ----
  static const double sgkRate = 0.14;
  static const double unemploymentRate = 0.01;
  static const double stampTaxRate = 0.00759;
  static const double asgariBrut = 33030.0;
  static const double sgkTavan = asgariBrut * 7.5;

  static const List<Map<String, double>> taxBrackets = [
    {"limit": 190000, "rate": 0.15},
    {"limit": 400000, "rate": 0.20},
    {"limit": 1500000, "rate": 0.27},
    {"limit": 5300000, "rate": 0.35},
    {"limit": double.infinity, "rate": 0.40},
  ];

  static double calculateOvertimeDynamic(double gross, List<Map<String, double>> overtimeList) {
    double hourly = gross / 225;
    double totalOvertime = 0;
    for (var item in overtimeList) {
      double hours = item["hours"] ?? 0;
      double rate = (item["rate"] ?? 0) / 100;
      totalOvertime += hourly * (rate) * hours;
    }
    return totalOvertime;
  }

  // MAAŞ HESAPLAMA - Kümülatifi içeride ay bilgisine göre çözer
  static double calculateNet({
    required double grossSalary,
    required List<Map<String, double>> overtimeList,
    required int month,
    double cumulativeGross = 0, // Arayüzden gelen yıl başı kümülatif brüt
  }) {
    // 1. Brüt ve Matrah Hesabı
    double overtime = calculateOvertimeDynamic(grossSalary, overtimeList);
    double totalGross = grossSalary + overtime;

    double sgkBase = totalGross > sgkTavan ? sgkTavan : totalGross;
    double kesintiMiktari = sgkBase * (sgkRate + unemploymentRate);
    double aylikMatrah = totalGross - kesintiMiktari;

    // 2. KÜMÜLATİF MATRAH (HAYALET MESAİ HATASI DÜZELTİLDİ)
    double calisanKumulatif = 0;
    if (cumulativeGross > 0) {
      // Eğer sen ekrana 160.000 yazdıysan, bunu matraha (136.000) çevirip kullanır
      calisanKumulatif = cumulativeGross * (1 - (sgkRate + unemploymentRate));
    } else {
      // Ekrana kümülatif girilmediyse, önceki ayları MESAİSİZ (düz maaş) farz et
      double baseSgk = grossSalary > sgkTavan ? sgkTavan : grossSalary;
      double baseMatrah = grossSalary - (baseSgk * (sgkRate + unemploymentRate));
      calisanKumulatif = baseMatrah * (month - 1); 
    }

    // 3. Gelir Vergisi 
    double rawIncomeTax = _calculateProgressiveTax(calisanKumulatif, aylikMatrah);

    // 4. Asgari Ücret İstisnası
    double asgariMatrah = asgariBrut * 0.85;
    double asgariKumulatif = asgariMatrah * (month - 1);
    double asgariVergiIstisnasi = _calculateProgressiveTax(asgariKumulatif, asgariMatrah);

    // 5. Kesintileri Netleştir
    double finalIncomeTax = (rawIncomeTax - asgariVergiIstisnasi).clamp(0, double.infinity);
    double finalStamp = (totalGross * stampTaxRate - asgariBrut * stampTaxRate).clamp(0, double.infinity);

    // 6. Sonuç
    double net = totalGross - kesintiMiktari - finalIncomeTax - finalStamp;
    return double.parse(net.toStringAsFixed(2));
  }

  // Vergi dilimi geçişlerini yöneten çekirdek fonksiyon
  static double _calculateProgressiveTax(double cumulative, double taxable) {
    double remaining = taxable;
    double tax = 0;
    double currentBase = cumulative;

    for (var bracket in taxBrackets) {
      double limit = bracket["limit"]!;
      double rate = bracket["rate"]!;
      double gap = limit - currentBase;

      if (remaining <= 0) break;
      if (gap > 0) {
        double chunk = remaining < gap ? remaining : gap;
        tax += chunk * rate;
        remaining -= chunk;
        currentBase += chunk;
      }
    }
    return tax;
  }
}