import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction_response.dart';

class TransactionDetailBottomSheet extends StatelessWidget {
  final TransactionResponse transaction;
  final VoidCallback onEdit;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
    required this.onEdit,
  });

  static void show(BuildContext context, TransactionResponse transaction, VoidCallback onEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailBottomSheet(
        transaction: transaction,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.category.type.toLowerCase() == 'income';
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 2);
    final String formattedDate = (transaction.transactionDate.hour == 0 && transaction.transactionDate.minute == 0)
        ? DateFormat('dd MMM yyyy').format(transaction.transactionDate)
        : DateFormat('dd MMM yyyy, HH:mm').format(transaction.transactionDate);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar & Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // Amount Display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
              style: GoogleFonts.kanit(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isIncome ? const Color(0xFF2D955F) : Colors.black,
              ),
            ),
          ),

          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isIncome ? const Color(0xFF2D955F).withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              transaction.category.categoryName,
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: isIncome ? const Color(0xFF2D955F) : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Detail List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildDetailRow('Date & Time', formattedDate),
                _buildDetailRow('Sender Bank', transaction.senderBank ?? '-'),
                _buildDetailRow('Receiver', transaction.receiverName ?? '-'),
                _buildDetailRow('Ref ID', transaction.transactionId),
                _buildDetailRow('Note', transaction.description.isNotEmpty ? transaction.description : '-'),
                
                const SizedBox(height: 16),
                

              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D955F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Edit Transaction',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: Colors.black45,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(String message) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.kanit(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
