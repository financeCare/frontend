import '../models/job_model.dart';

class JobService {
  Future<List<JobModel>> getSuggestedJobs() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Simulate a random network error (disabled by default for smooth demo)
      // if (DateTime.now().second % 10 == 0) {
      //   throw Exception('Simulated Network Error');
      // }

      return [
        JobModel(
          id: '1',
          title: 'พนักงานส่งอาหารดาวรุ่ง (Delivery Rider)',
          type: 'รายได้เสริม, ทำหลังเลิกงาน',
          estimatedIncome: '500 - 1,000 บาท/วัน',
          description:
              'ขับรถส่งอาหารกับแพลตฟอร์มชั้นนำ เลือกเวลาทำงานได้ตามใจชอบ เหมาะสำหรับคนมีมอเตอร์ไซค์ส่วนตัว',
          requirement: 'มีใบขับขี่รถจักรยานยนต์, สมาร์ทโฟน 1 เครื่อง',
          platformLinks: {
            'JobsDB': 'https://th.jobsdb.com/th/search-jobs/rider/1',
            'Fastwork': 'https://fastwork.co/search?q=rider',
          },
          isRecommended: true,
        ),
        JobModel(
          id: '2',
          title: 'รับจ้างคีย์ข้อมูล (Data Entry Freelance)',
          type: 'Work from Home',
          estimatedIncome: '300 - 600 บาท/วัน',
          description:
              'งานพิมพ์เอกสาร คีย์ข้อมูลลงระบบ สามารถทำที่บ้านได้ เหมาะสำหรับคนที่พิมพ์งานคล่องและมีคอมพิวเตอร์พกพา',
          requirement: 'คอมพิวเตอร์/โน้ตบุ๊ก, อินเทอร์เน็ต, ทักษะการพิมพ์ > 40 WPM',
          platformLinks: {
            'Fastwork': 'https://fastwork.co/search?q=คีย์ข้อมูล',
            'JobsDB': 'https://th.jobsdb.com/th/search-jobs/data-entry/1',
          },
        ),
        JobModel(
          id: '3',
          title: 'ติวเตอร์สอนพิเศษ (Part-time Tutor)',
          type: 'เสาร์-อาทิตย์, วันหยุด',
          estimatedIncome: '3,000 - 8,000 บาท/เดือน',
          description:
              'สอนหนังสือเด็กประถม-มัธยม ในรายวิชาที่ถนัด สามารถเลือกสอนแบบออนไลน์หรือนัดเจอสถานที่จริงได้',
          requirement: 'มีความเชี่ยวชาญในวิชาที่จะสอน, รักการสอนเด็ก',
          platformLinks: {
            'JobsDB': 'https://th.jobsdb.com/th/search-jobs/tutor/1',
            'Fastwork': 'https://fastwork.co/search?q=สอนพิเศษ',
          },
        ),
        JobModel(
          id: '4',
          title: 'พนักงานจัดเรียงสินค้า (Part-time Staff)',
          type: 'ทำงานเป็นกะ',
          estimatedIncome: '350 - 450 บาท/กะ (8 ชม.)',
          description:
              'จัดเรียงสินค้าหน้าร้านและโกดังของซูเปอร์มาร์เก็ต มีให้เลือกหลายสาขาใกล้บ้าน',
          requirement: 'อายุ 18 ปีขึ้นไป, สุขภาพร่างกายแข็งแรง',
          platformLinks: {
            'JobsDB': 'https://th.jobsdb.com/th/search-jobs/พนักงานห้าง/1',
          },
        ),
        JobModel(
          id: '5',
          title: 'แอดมินตอบแชทเพจ (Page Admin)',
          type: 'Work from Home',
          estimatedIncome: '4,000 - 6,000 บาท/เดือน',
          description:
              'ตอบคำถามลูกค้า ปิดการขาย คอนเฟิร์มออเดอร์ให้กับร้านค้าออนไลน์ มีสคริปต์ให้ ทำงานเป็นกะ 4-6 ชั่วโมง',
          requirement: 'มีสมาร์ทโฟน, พิมพ์ตอบโต้ภาษาไทยได้ถูกต้องและรวดเร็ว',
          platformLinks: {
            'Fastwork': 'https://fastwork.co/search?q=admin',
            'JobsDB': 'https://th.jobsdb.com/th/search-jobs/admin/1',
          },
          isRecommended: true,
        ),
      ];
    } catch (e) {
      print('JobService Error: $e');
      throw Exception('ไม่สามารถดึงข้อมูลอาชีพเสริมได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง');
    }
  }
}
