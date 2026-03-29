enum PaymentInterval {
  DAILY,
  WEEKLY,
  BI_WEEKLY,
  MONTHLY;

  String get label {
    switch (this) {
      case PaymentInterval.DAILY:
        return 'รายวัน';
      case PaymentInterval.WEEKLY:
        return 'รายสัปดาห์';
      case PaymentInterval.BI_WEEKLY:
        return 'ทุก 2 สัปดาห์';
      case PaymentInterval.MONTHLY:
        return 'รายเดือน';
    }
  }

  static PaymentInterval fromString(String? value) {
    return PaymentInterval.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentInterval.MONTHLY,
    );
  }
}
