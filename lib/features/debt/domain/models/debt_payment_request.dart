class DebtPaymentRequest {
  final String debtId;
  final double amount;
  final String paidAt;

  DebtPaymentRequest({
    required this.debtId,
    required this.amount,
    required this.paidAt,
  });

  Map<String, dynamic> toJson() {
    return {'debtId': debtId, 'amount': amount, 'paidAt': paidAt};
  }
}
