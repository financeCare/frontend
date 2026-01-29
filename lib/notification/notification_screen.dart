import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ข้อมูลจำลองการแจ้งเตือน
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'แจ้งเตือนครบกำหนดชำระ',
      'description': 'ค่าน้ำ-ค่าไฟ ประจำเดือนมกราคม ถึงกำหนดชำระวันนี้แล้ว',
      'time': '5 นาทีที่แล้ว',
      'type': 'bill',
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'เป้าหมายสำเร็จแล้ว!',
      'description': 'ยินดีด้วย! คุณเก็บเงินออมครบ 5,000 บาท ตามเป้าหมาย "เที่ยวญี่ปุ่น" แล้ว',
      'time': '2 ชั่วโมงที่แล้ว',
      'type': 'achievement',
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'โปรโมชั่นบัตรเครดิต',
      'description': 'รับเครดิตเงินคืน 5% เมื่อใช้จ่ายที่ซูเปอร์มาร์เก็ตที่ร่วมรายการ',
      'time': '1 วันที่แล้ว',
      'type': 'promo',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // ฟังก์ชันอ่านทั้งหมด
              setState(() {
                for (var n in notifications) {
                  n['isRead'] = true;
                }
              });
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'อ่านทั้งหมด',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return _buildNotificationItem(item);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    IconData iconData;
    Color iconColor;

    // เลือก Icon ตามประเภทการแจ้งเตือน
    switch (item['type']) {
      case 'bill':
        iconData = Icons.receipt_long;
        iconColor = Colors.redAccent;
        break;
      case 'achievement':
        iconData = Icons.stars;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications_active;
        iconColor = const Color(0xFF00796B);
    }

    return Container(
      color: item['isRead'] ? Colors.transparent : Colors.teal.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            fontWeight: item['isRead'] ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item['description']),
            const SizedBox(height: 4),
            Text(
              item['time'],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            item['isRead'] = true;
          });
          // สามารถใส่ Logic เพื่อเปิดหน้าละเอียดต่อไปได้ที่นี่
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือนใหม่',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}