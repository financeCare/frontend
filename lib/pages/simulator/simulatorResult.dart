import 'package:flutter/material.dart';
import 'RepaymentPayScreen.dart';

class SimulatorResultScreen extends StatefulWidget {
  final Map<String, dynamic>? resultFromPlan;

  const SimulatorResultScreen({super.key, this.resultFromPlan});

  @override
  State<SimulatorResultScreen> createState() =>
      _SimulatorResultScreenState();
}

class _SimulatorResultScreenState extends State<SimulatorResultScreen> {
  bool isLoading = true;
  Map<String, dynamic>? result;

  Map<String, dynamic> _mockResult() {
    return {
      "estimatedMonths": 12,
      "totalInterest": 35000,
      "totalPaid": 185000,
      "monthlyResults": List.generate(12, (i) {
        return {
          "month": i + 1,
          "payment": 7700,
          "interest": 1200,
          "principal": 6500,
          "remainingDebt": 185000 - ((i + 1) * 6500),
        };
      })
    };// อันนี้เป็น mock ข้อมูล (เอาไว้ดู design ตาราง) ถ้าใช้ api จริงๆแล้วลบได้เลย
  }

  @override
  void initState() {
    super.initState();
    result = _mockResult();
    isLoading = false;
  }

  // @override
  // void initState() {
  // super.initState();
  // if (widget.resultFromPlan != null) {
  // result = widget.resultFromPlan;
  // isLoading = false; // } else {
  // _load(); // fallback
  // }
  // }
  //  //อันนี้ api จริงๆ ถ้าใช้ api ได้ ใช้อันนี้

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlyResults =
        (result?['monthlyResults'] as List?) ?? [];

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text("ผลการจำลอง"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(theme),
            const SizedBox(height: 20),

            const Text(
              "แผนการจ่ายรายเดือน",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...monthlyResults.map((m) => _monthCard(m)).toList(),
            const SizedBox(height: 90),
          ],
        ),
      ),

      // ===== FLOAT BUTTON =====
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RepaymentPayScreen(),
                ),
              );
            },
            child: const Text(
              "ชำระหนี้จริง",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
    );
  }

  // ===== SUMMARY CARD =====
  Widget _summaryCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("สรุปแผน",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bigItem("ระยะเวลา",
                  "${result?['estimatedMonths']} เดือน"),
              _bigItem("ดอกเบี้ย",
                  "${result?['totalInterest']}"),
              _bigItem("ยอดรวม",
                  "${result?['totalPaid']}"),
            ],
          )
        ],
      ),
    );
  }

  Widget _bigItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ===== MONTH CARD =====
  Widget _monthCard(Map m) {
    final percent = (m['principal'] / m['payment']).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("เดือนที่ ${m['month']}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${m['payment']} บาท",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ดอก ${m['interest']}"),
              Text("เงินต้น ${m['principal']}"),
              Text("คงเหลือ ${m['remainingDebt']}"),
            ],
          ),
        ],
      ),
    );
  }
}
