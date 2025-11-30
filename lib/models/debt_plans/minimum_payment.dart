import '../debt_plan_model.dart';

final DebtPlan minimumPaymentPlan = DebtPlan(
  id: 'minimum_payment',
  name: 'Minimum Payment Plan',
  description: 'จ่ายขั้นต่ำตามที่ต้องจ่ายแต่ละเดือน',
  pros: ['ง่ายต่อการทำตาม', 'ควบคุมงบประมาณได้'],
  cons: ['ใช้เวลานาน, ดอกเบี้ยรวมมาก'],
);