import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/job_model.dart';
import '../../data/services/job_service.dart';
import '../widgets/job_card.dart';
import '../../../../core/services/location_service.dart';
import '../../../settings/data/services/user_setting_service.dart';

class JobSuggestionPage extends StatefulWidget {
  const JobSuggestionPage({super.key});

  @override
  State<JobSuggestionPage> createState() => _JobSuggestionPageState();
}

class _JobSuggestionPageState extends State<JobSuggestionPage> {
  final JobService _jobService = JobService();
  final LocationService _locationService = LocationService();
  final UserSettingService _userSettingService = UserSettingService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  List<JobModel> _jobs = [];
  bool _isLoading = true;
  String? _detectedProvince;
  String _selectedFilter = 'งานที่เหมาะกับคุณ';
  
  final List<String> _provinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น', 'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 
    'ชัยภูมิ', 'ชุมพร', 'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก', 'นครปฐม', 'นครพนม', 
    'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี', 'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์', 
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พะเยา', 'พังงา', 'พัทลุง', 'พิจิตร', 'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 
    'แพร่', 'ภูเก็ต', 'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยโสธร', 'ยะลา', 'ร้อยเอ็ด', 'ระนอง', 'ระยอง', 
    'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย', 'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 
    'สมุทรสงคราม', 'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย', 'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 
    'หนองบัวลำภู', 'อ่างทอง', 'อำนาจเจริญ', 'อุดรธานี', 'อุตรดิตถ์', 'อุทัยธานี', 'อุบลราชธานี'
  ];
  
  // New state for profile settings
  List<String> _selectedSkills = [];

  final List<String> _availableSkills = [
    'ขับรถ', 'คอมพิวเตอร์', 'ภาษาอังกฤษ', 'ภาษาไทย', 'การสื่อสาร', 
    'งานบริการ', 'งานช่าง', 'งานเขียน', 'ออกแบบ', 'ความอดทน', 
    'การตลาด', 'ศิลปะ', 'ถ่ายภาพ', 'แต่งภาพ', 'ดูแลสัตว์'
  ];

  final List<String> _filters = [
    'งานที่เหมาะกับคุณ',
    'งานทั้งหมด',
    'รายวัน',
    'รายเดือน',
    'Work from Home',
    'Freelance',
    'Part-time'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    // 1. Get current location
    final province = await _locationService.getCurrentProvince();
    
    // 2. Get debt status (logic removed)

    // 3. Get user profile for profession and skills
    try {
      final settings = await _userSettingService.fetchUserSettings();
      final userSetting = settings.userSetting;
      
      if (mounted) {
        setState(() {
          if (userSetting.skills != null && userSetting.skills!.isNotEmpty) {
            _selectedSkills = userSetting.skills!.split(',');
          } else {
            _selectedSkills = ['คอมพิวเตอร์']; // Default if none
          }
        });
      }
    } catch (e) {
      print('Error fetching user settings: $e');
      // Fallback to defaults
      if (mounted) {
        setState(() {
          _selectedSkills = ['คอมพิวเตอร์'];
        });
      }
    }

    if (mounted) {
      final translatedProvince = _translateProvince(province ?? '');
      setState(() {
        _detectedProvince = translatedProvince;
        _locationController.text = translatedProvince.isEmpty ? 'ประเทศไทย' : translatedProvince;
      });
    }

    await _loadJobs();
  }



  Future<void> _updateProfileAndLoadJobs() async {
    try {
      await _userSettingService.updateUserProfile(
        skills: _selectedSkills,
      );
    } catch (e) {
      print('Error updating profile: $e');
    }
    await _loadJobs();
  }

  Future<void> _loadJobs({String? keywords}) async {
    setState(() => _isLoading = true);
    try {
      String effectiveKeywords;
      
      if (_selectedFilter == 'งานที่เหมาะกับคุณ') {
        // ใช้ทักษะของผู้ใช้เป็นเกณฑ์
        String baseTerms = (_searchController.text.trim().isNotEmpty)
            ? _searchController.text.trim()
            : (_selectedSkills.isNotEmpty)
                ? _selectedSkills.join(" ")
                : "งาน";
        effectiveKeywords = baseTerms;
      } else if (_selectedFilter == 'งานทั้งหมด') {
        // ค้นหางานเสริมทั่วไปในพื้นที่
        effectiveKeywords = "งานเสริม";
      } else if (_selectedFilter == 'รายวัน') {
        effectiveKeywords = "รายวัน";
      } else if (_selectedFilter == 'รายเดือน') {
        effectiveKeywords = "รายเดือน";
      } else if (_selectedFilter == 'Part-time') {
        effectiveKeywords = "Part-time";
      } else {
        // ฟิลเตอร์อื่นๆ (เช่น Freelance, Work from Home) ก็ใช้ชื่อฟิลเตอร์เลย
        effectiveKeywords = _selectedFilter;
      }

      final String finalLocation = _locationController.text.isEmpty || _locationController.text == 'ประเทศไทย' 
          ? (_detectedProvince ?? '') 
          : _locationController.text;

      final jobs = await _jobService.getSuggestedJobs(
        keywords: keywords ?? effectiveKeywords,
        location: _translateProvince(finalLocation),
        skills: _selectedFilter == 'งานที่เหมาะกับคุณ' ? _selectedSkills : [],
      );
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
        );
      }
    }
  }

  List<JobModel> get _filteredJobs {
    if (_selectedFilter == 'งานที่เหมาะกับคุณ') {
      return _jobs.where((job) => job.isRecommended).toList();
    }
    // สำหรับฟิลเตอร์อื่นๆ เราใช้ API ในการกรองข้อมูลมาให้แล้วจาก Keywords
    return _jobs;
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                // Green Header Banner (Background)
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D955F),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                
                // Content Column (This defines the Stack's height and enables proper hit-testing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Text
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Profile Settings Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F0),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ตั้งค่าโปรไฟล์เพื่อคำนวณงานที่เหมาะ:',
                            style: GoogleFonts.kanit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'พื้นที่การทำงาน (ระบุจังหวัด):',
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showProvinceSelection,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _locationController.text.isEmpty ? 'เลือกจังหวัด' : _locationController.text,
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color: _locationController.text.isEmpty ? Colors.grey[400] : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Color(0xFF2D955F)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ทักษะที่คุณถนัด:',
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableSkills.map((skill) {
                              final isSelected = _selectedSkills.contains(skill);
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedSkills.remove(skill);
                                    } else {
                                      _selectedSkills.add(skill);
                                    }
                                  });
                                  _updateProfileAndLoadJobs();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2D955F) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2D955F) : Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: GoogleFonts.kanit(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), // Natural margin after card
                  ],
                ),
              ],
            ),

            // Calculation Status Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D955F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ระบบกำลังคำนวณงานที่เหมาะกับทักษะเฉพาะของคุณให้เป็นพิเศษ เพื่อช่วยให้คุณปลดหนี้ได้ไวขึ้น',
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: const Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),



            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  Text(
                    'ค้นหาประกาศรับสมัครงาน',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
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
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          filter,
                          style: GoogleFonts.kanit(
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                          _loadJobs(); // Trigger API load for the new filter keyword
                        }
                      },
                      selectedColor: const Color(0xFF2D955F),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2D955F) : Colors.grey.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Job List
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF2D955F))),
                  )
                : _filteredJobs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
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
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: _filteredJobs.length,
                        itemBuilder: (context, index) {
                          return JobCard(job: _filteredJobs[index]);
                        },
                      ),
            
            // Footer Note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Text(
                '* ข้อมูลงานอ้างอิงจาก Jooble ซึ่งเป็นแพลตฟอร์มรวบรวมงานที่ครอบคลุมที่สุด',
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showProvinceSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Text(
                        'เลือกจังหวัดที่ต้องการทำงาน',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _provinces.length,
                    itemBuilder: (context, index) {
                      final province = _provinces[index];
                      final isSelected = _locationController.text == province;
                      return ListTile(
                        onTap: () {
                          setState(() {
                            _locationController.text = province;
                          });
                          Navigator.pop(context);
                          _loadJobs();
                        },
                        title: Text(
                          province,
                          style: GoogleFonts.kanit(
                            color: isSelected ? const Color(0xFF2D955F) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF2D955F)) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  String _translateProvince(String name) {
    if (name.isEmpty) return "";
    String normalized = name.trim().toLowerCase();
    
    final Map<String, String> translationMap = {
      'bangkok': 'กรุงเทพมหานคร',
      'chiang mai': 'เชียงใหม่',
      'phuket': 'ภูเก็ต',
      'chon buri': 'ชลบุรี',
      'chonburi': 'ชลบุรี',
      'rayong': 'ระยอง',
      'khon kaen': 'ขอนแก่น',
      'nakhon ratchasima': 'นครราชสีมา',
      'samut prakan': 'สมุทรปราการ',
      'nonthaburi': 'นนทบุรี',
      'pathum thani': 'ปทุมธานี',
      'surat thani': 'สุราษฎร์ธานี',
      'songkhla': 'สงขลา',
      'chiang rai': 'เชียงราย',
      'ayutthaya': 'พระนครศรีอยุธยา',
      'phra nakhon si ayutthaya': 'พระนครศรีอยุธยา',
    };

    // Check mapping
    for (var entry in translationMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }

    // fallback to original if not found (might already be Thai)
    return name;
  }
}
