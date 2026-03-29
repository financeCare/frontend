import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../notification/data/services/slip_detection_service.dart';
import '../../../budget/domain/models/transaction_response.dart';

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
  final SlipDetectionService _slipService = SlipDetectionService();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 4.0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ขนาดไฟล์ใหญ่เกินไป กรุณาเลือกไฟล์ขนาดไม่เกิน 4MB'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _image = file;
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

    try {
      final TransactionResponse? result = await _slipService.processManualSlip(_image!);

      if (result != null) {
        setState(() {
          _ocrResult = "สแกนสำเร็จจากระบบ Python OCR";
          
          // แปลง TransactionResponse เป็น Map<String, String> สำหรับส่งต่อให้ AddTransactionScreen
          _structuredData = {
            "amount": result.amount.toString(),
            "receiver": result.receiverName ?? "ไม่พบข้อมูล",
            "sender": "-", // Backend ไม่ได้ส่ง sender name มาตรงๆ ใน TransactionResponse แต่ส่ง senderBank
            "sender_bank": result.senderBank ?? "ไม่พบข้อมูล",
            "date": result.transactionDate.toIso8601String(),
            "category_id": result.category.categoryId.toString(),
            "category_name": result.category.categoryName,
            "description": result.description,
            "image_path": result.imagePath ?? "",
            "slip_id": result.slipId?.toString() ?? "",
          };
          _isLoading = false;
        });
      } else {
        throw Exception("ไม่สามารถประมวลผลสลิปได้");
      }
    } catch (e) {
      setState(() {
        _ocrResult = "เกิดข้อผิดพลาด: $e";
        _structuredData = {};
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาดในการสแกน: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

// ปิดใช้งาน parsing แบบเก่า เนื่องจากใช้ Backend OCR แล้ว

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
                                    Navigator.pushNamed(
                                      context,
                                      '/add-transaction',
                                      arguments: _structuredData,
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 24),
                                  label: Text('บันทึกรายการนี้', style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D955F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(0x662D955F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/pay_debt',
                                      arguments: {
                                        'slipId': int.tryParse(_structuredData['slip_id'] ?? ''),
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 24),
                                  label: Text('ชำระหนี้ด้วยสลิปนี้', style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: const Color(0x663B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _copyToClipboard(context),
                                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                                  label: Text('คัดลอกข้อมูล', style: GoogleFonts.kanit(fontSize: 14)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
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
        _buildDataRow("คนรับเงิน", _structuredData["receiver"] ?? "ไม่พบข้อมูล"),
        _buildDataRow("ธนาคารต้นทาง", _structuredData["sender_bank"] ?? "ไม่พบข้อมูล"),
        _buildDataRow("จำนวนเงิน", "${_structuredData["amount"] ?? "0.00"} บาท"),
        _buildDataRow(
          "วันที่", 
          _structuredData["date"] != null 
              ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(_structuredData["date"]!))
              : "ไม่ระบุ"
        ),
        _buildDataRow("หมวดหมู่", _structuredData["category_name"] ?? "ไม่ระบุ"),
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
