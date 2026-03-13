import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/azure_vision_service.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _image;
  String _ocrResult = "";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final AzureVisionService _visionService = AzureVisionService();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _ocrResult = "";
      });
      _performOCR();
    }
  }

  Map<String, String> _structuredData = {};

  Future<void> _performOCR() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _ocrResult = "";
      _structuredData = {};
    });

    final result = await _visionService.analyzeImage(_image!);

    if (result != null) {
      setState(() {
        _ocrResult = result;
        _structuredData = _parseOCRText(result);
        _isLoading = false;
      });
    } else {
      setState(() {
        _ocrResult = "ไม่สามารถอ่านข้อความจากรูปภาพได้ หรือเกิดข้อผิดพลาด";
        _isLoading = false;
      });
    }
  }

  Map<String, String> _parseOCRText(String text) {
    Map<String, String> data = {
      "sender": "-",
      "receiver": "-",
      "date": "-",
      "amount": "-",
    };

    final lines = text.split('\n');
    final bankNames = [
      "กสิกร", "Kasikorn", "Krungsri", "ttb", "กรุงเทพ", "Bangkok Bank", 
      "กรุงไทย", "Krungthai", "ไทยพาณิชย์", "SCB", "ออมสิน", "GSB", 
      "PromptPay", "พรอ้มเพย", "ธนาคาร"
    ];
    final months = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
    
    List<String> potentialNames = [];
    String? firstMoneyPattern;
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // 1. Date Detection (Improved multi-line merging)
      if (data["date"] == "-") {
        bool hasMonth = months.any((m) => line.contains(m));
        bool hasYear = RegExp(r'25\d{2}|20\d{2}').hasMatch(line);
        bool hasTime = RegExp(r'\d{1,2}:\d{2}').hasMatch(line);
        
        if (hasMonth && (hasYear || hasTime)) {
          String dateValue = line;
          if (!hasTime && i + 1 < lines.length && RegExp(r'\d{1,2}:\d{2}').hasMatch(lines[i + 1])) {
             dateValue += " " + lines[i+1].trim();
          }
          data["date"] = dateValue;
        }
      }

      // 2. Amount Detection
      final amountMatch = RegExp(r'(\d{1,3}(,\d{3})*(\.\d{2}))').firstMatch(line);
      if (amountMatch != null) {
        String matchValue = amountMatch.group(0)!;
        firstMoneyPattern ??= matchValue;
        
        if (data["amount"] == "-") {
          bool hasAmountContext = line.contains('บาท') || line.contains('THB') || line.contains('จำนวน');
          int startIdx = (i - 10 < 0) ? 0 : i - 10;
          if (!hasAmountContext) {
            hasAmountContext = lines.sublist(startIdx, i + 1).any((l) => l.contains('จำนวนเงิน') || l.contains('Amount'));
          }
          if (hasAmountContext) {
            data["amount"] = matchValue;
          }
        }
      }

      // 3. Collect "Name-like" lines (Universal Extraction)
      // Criteria: 2+ words, no digits, not a bank name, not a status line
      bool isBank = bankNames.any((b) => line.contains(b));
      bool hasDigits = RegExp(r'\d').hasMatch(line);
      bool isStatus = line.contains("โอนเงินสำเร็จ") || line.contains("รายการสำเร็จ");
      List<String> words = line.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      
      if (!isBank && !hasDigits && !isStatus && words.length >= 2 && line.length > 5) {
        if (!potentialNames.contains(line)) {
          potentialNames.add(line);
        }
      }

      // 4. Keyword-based matching (High priority)
      String lowerLine = line.toLowerCase();
      if (lowerLine.contains("จาก") || lowerLine.contains("from")) {
        _extractNameAfterKeyword(line, i, lines, (name) => data["sender"] = name);
      }
      if (lowerLine.contains("ไปยัง") || lowerLine.contains("to") || lowerLine.contains("โอนให้")) {
        _extractNameAfterKeyword(line, i, lines, (name) => data["receiver"] = name);
      }
    }

    // Assign names if keywords failed
    if (data["sender"] == "-" && potentialNames.isNotEmpty) {
      data["sender"] = potentialNames[0];
    }
    if (data["receiver"] == "-" && potentialNames.length > 1) {
      // Receiver is usually the last person named in the main flow
      data["receiver"] = potentialNames.last;
    }

    // Final fallback for amount
    if (data["amount"] == "-" && firstMoneyPattern != null) {
      data["amount"] = firstMoneyPattern;
    }

    return data;
  }

  void _extractNameAfterKeyword(String line, int index, List<String> lines, Function(String) assign) {
    // Try next line first (most common)
    if (index + 1 < lines.length) {
      String nextLine = lines[index + 1].trim();
      if (nextLine.isNotEmpty && nextLine.split(" ").length >= 2 && !RegExp(r'\d').hasMatch(nextLine)) {
        assign(nextLine);
        return;
      }
    }
    // Try same line
    String remaining = "";
    if (line.contains("จาก")) remaining = line.split("จาก").last.trim();
    else if (line.contains("ไปยัง")) remaining = line.split("ไปยัง").last.trim();
    
    if (remaining.split(" ").length >= 2 && !RegExp(r'\d').hasMatch(remaining)) {
      assign(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D955F),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'สแกนใบเสร็จ (OCR)',
          style: GoogleFonts.kanit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D955F), Color(0xFF4CB07D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x332D955F),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ดึงข้อมูลอัตโนมัติ',
                      style: GoogleFonts.kanit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เปลี่ยนสลิปเป็นข้อมูล',
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'สแกนสลิปโอนเงินของคุณเพื่อแยกชื่อและจำนวนเงินโดยอัตโนมัติ',
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 13,
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

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกรูปภาพสลิป',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Image Preview Area (Show Full Image)
                    GestureDetector(
                      onTap: () => _showPickImageOptions(),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 220, maxHeight: 400),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: Color(0xFF2D955F),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'แตะเพื่ออัปโหลดรูปภาพ',
                                    style: GoogleFonts.kanit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2D955F),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'รองรับ JPG, PNG',
                                    style: GoogleFonts.kanit(
                                      fontSize: 13,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(_image!, fit: BoxFit.contain),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Result Area
                    if (_isLoading || _structuredData.isNotEmpty) ...[
                      Text(
                        'ผลการสแกน (สรุปข้อมูล)',
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF2D955F)),
                                const SizedBox(height: 16),
                                Text(
                                  'กำลังใช้ AI วิเคราะห์สลิป...',
                                  style: GoogleFonts.kanit(color: const Color(0xFF64748B)),
                                )
                              ],
                            )
                          : _structuredData.isEmpty
                              ? Center(
                                  child: Text(
                                    'เลือกรูปภาพเพื่อเริ่มการสแกน',
                                    style: GoogleFonts.kanit(color: const Color(0xFF94A3B8)),
                                  ),
                                )
                              : _buildResultTable(),
                    ),
                    
                    const SizedBox(height: 16),
              
              // Raw Data (Optional/Expandable)
              if (_ocrResult.isNotEmpty && !_isLoading)
                 Theme(
                   data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                   child: ExpansionTile(
                    title: Text('ดูข้อความดิบ (Raw Text)', style: GoogleFonts.kanit(fontSize: 12, color: Colors.black38)),
                    children: [
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Text(_ocrResult, style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45)),
                       )
                    ],
                                   ),
                 ),

              const SizedBox(height: 16),
              
                    // Actions
                    if (_ocrResult.isNotEmpty && !_isLoading)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Copy to clipboard or handle data
                                    _copyToClipboard(context);
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 20),
                                  label: Text('คัดลอกข้อมูล', style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D955F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _image = null;
                                      _ocrResult = "";
                                      _structuredData = {};
                                    });
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  label: Text('สแกนสลิปใหม่', style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2D955F),
                                    side: const BorderSide(color: Color(0xFF2D955F), width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('เลือกจากแกลเลอรี่', style: GoogleFonts.kanit()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('ถ่ายรูป', style: GoogleFonts.kanit()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    // In a real app we'd use Clipboard.setData
    // For now just show a Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกข้อความแล้ว')),
    );
  }

  Widget _buildResultTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      children: [
        _buildDataRow("ชื่อคนโอน", _structuredData["sender"]!),
        _buildDataRow("คนรับเงิน", _structuredData["receiver"]!),
        _buildDataRow("วันที่โอน", _structuredData["date"]!),
        _buildDataRow("จำนวนเงิน", "${_structuredData["amount"]!} บาท"),
      ],
    );
  }

  TableRow _buildDataRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            value,
            style: GoogleFonts.kanit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
