enum InterestCalculationType {
  THIRTY_360,      // ธนาคารทั่วไป
  DAILY_SIMPLE,    // นอกระบบทั่วไป
  DAILY_COMPOUND,  // ทบดอกทุกวัน
  FLAT_RATE;       // ดอกคิดบนเงินต้นเต็มตลอด

  String get label {
    switch (this) {
      case InterestCalculationType.THIRTY_360:
        return 'ธนาคารทั่วไป (30/360)';
      case InterestCalculationType.DAILY_SIMPLE:
        return 'นอกระบบทั่วไป (Simple Daily)';
      case InterestCalculationType.DAILY_COMPOUND:
        return 'ทบดอกทุกวัน (Compound Daily)';
      case InterestCalculationType.FLAT_RATE:
        return 'ดอกคิดบนเงินต้นเต็มตลอด (Flat Rate)';
    }
  }

  static InterestCalculationType fromString(String value) {
    return InterestCalculationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InterestCalculationType.THIRTY_360,
    );
  }
}
