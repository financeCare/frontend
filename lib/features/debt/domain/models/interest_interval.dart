enum InterestInterval {
  DAILY,
  WEEKLY,
  MONTHLY,
  YEARLY;

  String get label {
    switch (this) {
      case InterestInterval.DAILY:
        return 'รายวัน';
      case InterestInterval.WEEKLY:
        return 'รายสัปดาห์';
      case InterestInterval.MONTHLY:
        return 'รายเดือน';
      case InterestInterval.YEARLY:
        return 'รายปี';
    }
  }

  static InterestInterval fromString(String? value) {
    return InterestInterval.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InterestInterval.YEARLY, // Default to YEARLY for bank debts
    );
  }
}
