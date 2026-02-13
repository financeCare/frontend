import 'package:flutter/material.dart';

class RepaymentPayScreen extends StatefulWidget {
  const RepaymentPayScreen({super.key});

  @override
  State<RepaymentPayScreen> createState() => _RepaymentPayScreenState();
}

class _RepaymentPayScreenState extends State<RepaymentPayScreen> {
  String selectedDebt = "บัตรเครดิต A";
  double amount = 0;
  DateTime selectedDate = DateTime.now();
  String channel = "Mobile Banking";

  final debts = const [
    {"name": "บัตรเครดิต A", "balance": 845000},
    {"name": "สินเชื่อส่วนบุคคล", "balance": 120000},
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(title: const Text("บันทึกการชำระหนี้")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== เลือกหนี้ =====
            Row(
              children: debts.map((d) {
                final isActive = selectedDebt == d["name"];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedDebt = d["name"] as String);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.white,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.credit_card),
                          const SizedBox(height: 6),
                          Text(d["name"].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("ยอดคงค้าง ${d["balance"]} บาท"),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ===== จำนวนเงิน =====
            const Text("ระบุจำนวนเงินที่จ่าย (บาท)"),
            const SizedBox(height: 8),
            Text(
              amount.toStringAsFixed(2),
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: amount,
              min: 0,
              max: 50000,
              divisions: 100,
              onChanged: (v) {
                setState(() => amount = v);
              },
            ),

            const SizedBox(height: 12),

            // ===== วันที่ =====
            ListTile(
              title: const Text("วันที่ชำระ"),
              trailing: Text(
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),

            // ===== ช่องทาง =====
            ListTile(
              title: const Text("ช่องทางชำระเงิน"),
              trailing: DropdownButton<String>(
                value: channel,
                items: const [
                  DropdownMenuItem(
                      value: "Mobile Banking",
                      child: Text("Mobile Banking")),
                  DropdownMenuItem(value: "เงินสด", child: Text("เงินสด")),
                ],
                onChanged: (v) => setState(() => channel = v!),
              ),
            ),

            const Spacer(),

            // ===== ยืนยัน =====
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("บันทึกการชำระเรียบร้อย")),
                );
                Navigator.pop(context);
              },
              child: const Text("ยืนยันการบันทึก",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
