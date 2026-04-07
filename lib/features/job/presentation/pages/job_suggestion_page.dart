import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/job_model.dart';
import '../../data/models/occupation_model.dart';
import '../../data/services/job_service.dart';
import '../widgets/job_card.dart';
import '../../../../core/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<OccupationModel> _occupations = [];
  bool _isLoading = true;
  bool _isOccupationsLoading = true;
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

    await _loadOccupations();
    await _loadJobs();
  }

  Future<void> _loadOccupations() async {
    setState(() => _isOccupationsLoading = true);
    try {
      final occupations = await _jobService.getRecommendedOccupations();
      if (mounted) {
        setState(() {
          _occupations = occupations;
          _isOccupationsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading occupations: $e');
      if (mounted) setState(() => _isOccupationsLoading = false);
    }
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

            // Recommended Occupations Discovery
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Text(
                    'แนะนำไอเดียอาชีพเสริม',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            _isOccupationsLoading
                ? const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()))
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _occupations.length,
                      itemBuilder: (context, index) {
                        return _buildOccupationCard(_occupations[index]);
                      },
                    ),
                  ),

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

  Widget _buildOccupationCard(OccupationModel occupation) {
    return GestureDetector(
      onTap: () {
        if (occupation.externalUrl != null) {
          _showOccupationChoiceSheet(occupation);
        } else {
          _searchController.text = occupation.potentialKeywords;
          _loadJobs(keywords: occupation.potentialKeywords);
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: occupation.isBestMatch 
                  ? const Color(0xFFF59E0B).withOpacity(0.15) 
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: occupation.isBestMatch 
                ? const Color(0xFFF59E0B).withOpacity(0.5) 
                : const Color(0xFFF3F4F6),
            width: occupation.isBestMatch ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: occupation.isBestMatch 
                        ? const Color(0xFFFFF7ED) 
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getOccupationIcon(occupation.iconType),
                    color: occupation.isBestMatch 
                        ? const Color(0xFFD97706) 
                        : const Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  occupation.title,
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'เฉลี่ย: ',
                  style: GoogleFonts.kanit(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  occupation.averageIncome,
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: occupation.isBestMatch 
                        ? const Color(0xFFD97706) 
                        : const Color(0xFF059669),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'ดูประกาศงาน',
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: occupation.isBestMatch 
                            ? const Color(0xFFD97706) 
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward, 
                      size: 12, 
                      color: occupation.isBestMatch 
                          ? const Color(0xFFD97706) 
                          : const Color(0xFF3B82F6)
                    ),
                  ],
                ),
              ],
            ),
            if (occupation.isBestMatch)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 8, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        'ดีที่สุด',
                        style: GoogleFonts.kanit(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getOccupationIcon(String type) {
    switch (type) {
      case 'delivery': return Icons.delivery_dining;
      case 'computer': return Icons.laptop_mac;
      case 'teaching': return Icons.school_outlined;
      case 'sales': return Icons.storefront_outlined;
      case 'car': return Icons.directions_car_filled_outlined;
      case 'service': return Icons.home_repair_service_outlined;
      case 'event': return Icons.event_available;
      case 'pet': return Icons.pets;
      case 'admin': return Icons.support_agent;
      case 'writing': return Icons.edit_note;
      case 'staff': return Icons.coffee;
      case 'video': return Icons.video_library;
      case 'resell': return Icons.loop;
      case 'shopping': return Icons.shopping_bag;
      case 'package': return Icons.inventory_2;
      case 'mystery': return Icons.search;
      case 'fitness': return Icons.fitness_center;
      case 'old': return Icons.elderly;
      case 'beauty': return Icons.brush;
      case 'house': return Icons.home;
      case 'laundry': return Icons.local_laundry_service;
      case 'handmade': return Icons.palette;
      default: return Icons.work_outline;
    }
  }

  void _showOccupationChoiceSheet(OccupationModel occupation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getOccupationIcon(occupation.iconType),
                    color: const Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occupation.title,
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'เลือกช่องทางที่คุณสนใจ',
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Option 1: Jooble
            _buildActionTile(
              icon: Icons.search_outlined,
              title: 'ค้นหาประกาศงานบน Jooble',
              subtitle: 'ดูประกาศรับสมัครจากบริษัทหรือบริษัทจัดหางาน',
              onTap: () {
                Navigator.pop(context);
                _searchController.text = occupation.potentialKeywords;
                _loadJobs(keywords: occupation.potentialKeywords);
              },
            ),
            const SizedBox(height: 12),
            
            // Option 2: Direct Platform
            if (occupation.externalUrl != null)
              _buildActionTile(
                icon: Icons.open_in_new_outlined,
                title: 'สมัครผ่าน ${occupation.platformName} โดยตรง',
                subtitle: 'สมัครงานอิสระ (Gig Economy) บนแพลตฟอร์มพาร์ทเนอร์',
                isPrimary: true,
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(occupation.externalUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? const Color(0xFF3B82F6).withOpacity(0.3) : const Color(0xFFF3F4F6),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white : const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isPrimary ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.kanit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isPrimary ? const Color(0xFF3B82F6) : Colors.grey[400],
              size: 20,
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
