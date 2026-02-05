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
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final String? refType = args?['refType']?.toString();
    final String? refId = args?['refId']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          // ✅ ถ้ามาจากการกด notification: แสดงแถบ info ด้านบน
          if ((refType != null && refType.isNotEmpty) ||
              (refId != null && refId.isNotEmpty))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00796B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'เปิดจากแจ้งเตือน: refType=${refType ?? "-"}  refId=${refId ?? "-"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ✅ รายการแจ้งเตือน
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(notifications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    IconData iconData;
    Color iconColor;

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

    final bool isRead = item['isRead'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          item['title']?.toString() ?? '',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['description']?.toString() ?? ''),
              const SizedBox(height: 6),
              Text(
                item['time']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        onTap: () {
          setState(() {
            item['isRead'] = true;
          });

          // TODO: ถ้าอยากเปิดหน้ารายละเอียดจริง ๆ:
          // Navigator.pushNamed(context, '/debt_detail', arguments: {...});
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[400]),
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
