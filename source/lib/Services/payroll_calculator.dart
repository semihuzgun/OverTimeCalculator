class PayrollCalculator {
  // ---- SABİTLER 2026 ----
  static const double sgkRate = 0.14;
  static const double unemploymentRate = 0.01;
  static const double stampTaxRate = 0.00759;

  static const double sgkTavan = 150018.90; // teyit et
  static const double asgariBrut = 33030; // 2026 günceli kontrol et

  // 2026 gelir vergisi dilimleri
  static const List<Map<String, double>> taxBrackets = [
    {"limit": 110000, "rate": 0.15},
    {"limit": 230000, "rate": 0.20},
    {"limit": 580000, "rate": 0.27},
    {"limit": 3000000, "rate": 0.35},
    {"limit": double.infinity, "rate": 0.40},
  ];

  static double calculateHourly(double gross) {
    return gross / 225;
  }

  static double calculateOvertimeDynamic(
    double gross,
    List<Map<String, double>> overtimeList,
  ) {
    double hourly = calculateHourly(gross);
    double totalOvertime = 0;

    for (var item in overtimeList) {
      double hours = item["hours"] ?? 0;
      double rate = (item["rate"] ?? 100) / 100;
      totalOvertime += hourly * rate * hours;
    }

    return totalOvertime;
  }

  static double calculateNet({
    required double grossSalary,
    required List<Map<String, double>> overtimeList,
    required double cumulativeBase,
  }) {
    double overtime = calculateOvertimeDynamic(grossSalary, overtimeList);
    double totalGross = grossSalary + overtime;

    // SGK tavan kontrolü
    double sgkBase = totalGross > sgkTavan ? sgkTavan : totalGross;

    double sgk = sgkBase * sgkRate;
    double unemployment = sgkBase * unemploymentRate;

    double taxableIncome = totalGross - sgk - unemployment;

    // Gelir vergisi (kademeli)
    double incomeTax =
        _calculateProgressiveTax(cumulativeBase, taxableIncome);

    // ---- ASGARİ ÜCRET GV İSTİSNASI ----
    double asgariSgk = asgariBrut * sgkRate;
    double asgariIssizlik = asgariBrut * unemploymentRate;
    double asgariMatrah =
        asgariBrut - asgariSgk - asgariIssizlik;

    double asgariVergi =
        _calculateProgressiveTax(cumulativeBase, asgariMatrah);

    double finalIncomeTax =
        (incomeTax - asgariVergi) < 0 ? 0 : incomeTax - asgariVergi;

    // ---- DAMGA VERGİSİ ----
    double stampTax = totalGross * stampTaxRate;
    double asgariStamp = asgariBrut * stampTaxRate;

    double finalStamp =
        (stampTax - asgariStamp) < 0 ? 0 : stampTax - asgariStamp;

    return totalGross -
        sgk -
        unemployment -
        finalIncomeTax -
        finalStamp;
  }

  static double _calculateProgressiveTax(
      double cumulative, double taxable) {
    double remaining = taxable;
    double tax = 0;
    double currentBase = cumulative;

    for (var bracket in taxBrackets) {
      double limit = bracket["limit"]!;
      double rate = bracket["rate"]!;

      double bracketRemaining = limit - currentBase;

      if (remaining <= 0) break;

      if (bracketRemaining > 0) {
        double taxableInBracket =
            remaining < bracketRemaining ? remaining : bracketRemaining;

        tax += taxableInBracket * rate;
        remaining -= taxableInBracket;
        currentBase += taxableInBracket;
      }
    }

    return tax;
  }
}