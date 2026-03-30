import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/job_model.dart';
import '../../data/services/job_service.dart';
import '../widgets/job_card.dart';

class JobSuggestionPage extends StatefulWidget {
  const JobSuggestionPage({super.key});

  @override
  State<JobSuggestionPage> createState() => _JobSuggestionPageState();
}

class _JobSuggestionPageState extends State<JobSuggestionPage> {
  final JobService _jobService = JobService();
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'ทั้งหมด';

  final List<String> _filters = [
    'ทั้งหมด',
    'แนะนำ',
    'Work from Home',
    'หลังเลิกงาน',
    'เสาร์-อาทิตย์'
  ];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _jobService.getSuggestedJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
        );
      }
    }
  }

  List<JobModel> get _filteredJobs {
    if (_selectedFilter == 'ทั้งหมด') return _jobs;
    if (_selectedFilter == 'แนะนำ') {
      return _jobs.where((job) => job.isRecommended).toList();
    }
    return _jobs.where((job) => job.type.contains(_selectedFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D955F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'แนะนำอาชีพเสริม',
          style: GoogleFonts.kanit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D955F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เพิ่มโอกาส เพิ่มรายได้',
                  style: GoogleFonts.kanit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ปลดหนี้ให้ไวขึ้น!',
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'เราช่วยคัดสรรอาชีพเสริมที่เหมาะกับคุณ เพื่อเพิ่มรายได้และปลดหนี้ได้รวดเร็วยิ่งขึ้น',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text(
                  'หมวดหมู่งาน',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.kanit(
                        color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    selectedColor: const Color(0xFF2D955F),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2D955F) : Colors.grey.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Job List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D955F)))
                : _filteredJobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่พบงานในหมวดหมู่นี้',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        color: const Color(0xFF2D955F),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32, top: 8),
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            return JobCard(job: _filteredJobs[index]);
                          },
                        ),
                      ),
          ),
          // Footer Note (Disclaimer for Presentation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                   Icon(Icons.tips_and_updates_rounded, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'หมายเหตุ: ระบบเลือกแนะนำงานจาก JobsDB และ Fastwork เนื่องจากเป็นแพลตฟอร์มที่ได้รับความนิยมและมีความน่าเชื่อถือสูงสุดในปัจจุบัน',
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
