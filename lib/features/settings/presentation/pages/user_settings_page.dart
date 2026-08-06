import 'package:flutter/material.dart';
import 'package:finance_care/features/auth/data/services/device_service.dart';
import 'package:finance_care/features/settings/data/models/user_setting_response.dart';
import 'package:finance_care/features/settings/data/services/user_setting_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../auth/presentation/auth_manager.dart';

class UserSettingsPage extends StatefulWidget {
  final VoidCallback onBack;

  const UserSettingsPage({super.key, required this.onBack});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final UserSettingService _service = UserSettingService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _isLoading = true;
  UserSettingOverview? _data;
  String? _currentDeviceId;

  // Local state for notification settings
  bool _notificationsEnabled = false;
  String _defaultNotifyTime = "00:00:00";
  int _defaultRemindDaysBefore = 1;

  final TextEditingController _salaryController = TextEditingController();
  final FocusNode _salaryFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSalaryInvalid = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmDialog(
      title: 'ออกจากระบบ',
      message: 'คุณแน่ใจหรือว่าต้องการออกจากระบบบัญชีของคุณในขณะนี้?',
      confirmText: 'ออกจากระบบ',
      confirmColor: const Color(0xFFEB5757),
      icon: Icons.logout_rounded,
    );

    if (confirmed != true) return;

    try {
      await LineSDK.instance.logout();
      await _googleSignIn.signOut();
      await AuthManager.logout();
    } catch (e) {
      debugPrint("Logout failed: $e");
    }
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final deviceKey = await DeviceService.getOrCreateDeviceId();
      final data = await _service.fetchUserSettings();

      if (!mounted) return;
      setState(() {
        _data = data;
        _currentDeviceId = deviceKey;
        _notificationsEnabled = data.userSetting.notificationsEnabled;
        _defaultNotifyTime = data.userSetting.defaultNotifyTime;
        _defaultRemindDaysBefore = data.userSetting.defaultRemindDaysBefore;
        if (!_isLoading) {
          _isLoading =
              false; // Only set loading false if both done (or handle independently)
        }
      });
    } catch (e) {
      debugPrint("Error loading user settings: $e");
    }

    try {
      final salary = await _service.getSalary();
      if (!mounted) return;
      setState(() {
        if (salary > 0 || _salaryController.text.isEmpty) {
          _salaryController.text = salary.toStringAsFixed(0);
        }
      });
    } catch (e) {
      debugPrint("Error loading salary: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final confirmed = await _showConfirmDialog(
      title: 'บันทึกการตั้งค่า',
      message: 'คุณต้องการบันทึกการเปลี่ยนแปลงทั้งหมดของการตั้งค่าใช่หรือไม่?',
      confirmText: 'บันทึก',
      confirmColor: const Color(0xFF27AE60),
      icon: Icons.save_as_rounded,
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _isSalaryInvalid = false;
    });
    try {
      final salaryAmount = double.tryParse(_salaryController.text) ?? 0.0;

      if (salaryAmount <= 0) {
        setState(() {
          _isLoading = false;
          _isSalaryInvalid = true;
        });
        
        // Auto-scroll to top and focus the field
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _salaryFocusNode.requestFocus();
        
        return;
      }

      await Future.wait([
        _service.updateNotificationSettings(
          enabled: _notificationsEnabled,
          time: _defaultNotifyTime,
          daysBefore: _defaultRemindDaysBefore,
        ),
        _service.setSalary(salaryAmount),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'บันทึกการตั้งค่าเสร็จสมบูรณ์',
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 4,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      await _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('มีข้อผิดพลาดในการบันทึกการตั้งค่า: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: confirmColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.black.withOpacity(0.1)),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: GoogleFonts.kanit(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: GoogleFonts.kanit(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDevice(String deviceId) async {
    final confirmed = await _showConfirmDialog(
      title: 'ลบอุปกรณ์',
      message: 'คุณแน่ใจหรือไม่ว่าต้องการลบอุปกรณ์นี้?\nหากลบแล้วอุปกรณ์นี้จะถูกออกจากระบบทันที',
      confirmText: 'ลบอุปกรณ์',
      confirmColor: const Color(0xFFEB5757),
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _service.deleteDevice(deviceId);
        await _loadSettings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('มีข้อผิดพลาดในการลบอุปกรณ์: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _selectTime() async {
    final cur = _defaultNotifyTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(cur[0]),
      minute: int.parse(cur[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _defaultNotifyTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      });
    }
  }

  void _showDaysPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'แจ้งเตือนล่วงหน้า',
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เลือกจำนวนวันที่คุณต้องการรับการแจ้งเตือนก่อนวันจริง',
              style: GoogleFonts.kanit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final val = index + 1;
                  final isSelected = _defaultRemindDaysBefore == val;
                  return InkWell(
                    onTap: () {
                      setState(() => _defaultRemindDaysBefore = val);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF27AE60).withOpacity(0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF27AE60).withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$val วันก่อนหน้า',
                            style: GoogleFonts.kanit(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF27AE60)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF27AE60),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _salaryFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading && _data == null
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2D955F)),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildSalarySection(),
                              const SizedBox(height: 16),
                              _buildNotificationSection(),
                              const SizedBox(height: 16),
                              if (_data != null)
                                _buildDeviceSection(_data!.devices),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                              _buildLogoutButton(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.05),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2D955F),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'ตั้งค่า',
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // IconButton removed as requested
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF27AE60)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSalarySection() {
    return _buildCard(
      children: [
        _buildSectionHeader(
          Icons.account_balance_wallet_outlined,
          'ข้อมูลรายได้',
          'ตั้งค่ารายได้รายเดือนของคุณเพื่อใช้ในการวางแผนการชำระหนี้',
        ),
        Text(
          'เงินเดือนปัจจุบัน',
          style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isSalaryInvalid
                  ? Colors.red
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextField(
            controller: _salaryController,
            focusNode: _salaryFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              if (_isSalaryInvalid) setState(() => _isSalaryInvalid = false);
            },
            style: GoogleFonts.kanit(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'กรอกเงินเดือนของคุณ',
              hintStyle: GoogleFonts.kanit(color: Colors.black38),
              border: InputBorder.none,
              prefixText: '฿ ',
              prefixStyle: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF27AE60),
              ),
            ),
          ),
        ),
        if (_isSalaryInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'กรุณากรอกเงินเดือนให้ถูกต้อง (มากกว่า 0)',
              style: GoogleFonts.kanit(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildCard(
      children: [
        _buildSectionHeader(
          Icons.notifications_none,
          'การแจ้งเตือน',
          'ตั้งค่าวิธีการและเวลาที่คุณจะได้รับข้อความแจ้งเตือนเกี่ยวกับการชำระเงินที่กำลังจะมาถึง',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เปิดใช้งานการแจ้งเตือน',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'รับการแจ้งเตือนก่อนวันครบกำหนดชำระเงินของคุณ',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
                activeThumbColor: const Color(0xFF2ECC71),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'เวลาแจ้งเตือนเริ่มต้น',
          style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          'ตั้งเวลาที่คุณต้องการรับการแจ้งเตือนในแต่ละวัน',
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _defaultNotifyTime,
                  style: GoogleFonts.kanit(fontSize: 14),
                ),
                const Icon(Icons.access_time, size: 18, color: Colors.black45),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'จำนวนวันที่แจ้งเตือนก่อนวันครบกำหนด',
          style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          'คุณต้องการให้เราแจ้งเตือนล่วงหน้ากี่วัน?',
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showDaysPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_defaultRemindDaysBefore วันก่อนหน้า',
                  style: GoogleFonts.kanit(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black45),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSection(List<UserDevice> devices) {
    return _buildCard(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.phone_iphone,
                  size: 18,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 8),
                Text(
                  'อุปกรณ์',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${devices.length} เครื่อง',
                style: GoogleFonts.kanit(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'จัดการอุปกรณ์ที่เข้าสู่ระบบด้วยบัญชีของคุณในปัจจุบัน',
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 16),
        ...devices.map((device) => _buildDeviceItem(device)),
      ],
    );
  }

  Widget _buildDeviceItem(UserDevice device) {
    final isCurrent = device.deviceId == _currentDeviceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFF1F8F4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF27AE60).withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFF27AE60)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              device.platform.toLowerCase() == 'ios' ||
                      device.deviceName.toLowerCase().contains('iphone')
                  ? Icons.phone_iphone
                  : Icons.smartphone,
              color: isCurrent ? Colors.white : Colors.black45,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.deviceName,
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'อุปกรณ์นี้',
                          style: GoogleFonts.kanit(
                            fontSize: 10,
                            color: const Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildInfoItem(Icons.language, device.platform, size: 12),
                    _buildInfoItem(
                      Icons.location_on_outlined,
                      'กรุงเทพมหานคร, ประเทศไทย',
                      size: 12,
                    ),
                    _buildInfoItem(Icons.access_time, 'ใช้งานอยู่', size: 12),
                  ],
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.black38,
              ),
              onPressed: () => _deleteDevice(device.deviceId),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, {double size = 11}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 2, color: Colors.black38),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.kanit(fontSize: size, color: Colors.black45),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final confirmed = await _showConfirmDialog(
                title: 'รีเซ็ตข้อมูล',
                message: 'คุณต้องการย้อนกลับไปใช้ค่าเดิมที่บันทึกไว้ใช่หรือไม่? ข้อมูลที่คุณแก้ไขจะหายไป',
                confirmText: 'รีเซ็ต',
                confirmColor: const Color(0xFF64748B),
                icon: Icons.refresh_rounded,
              );
              if (confirmed == true) {
                _loadSettings();
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            child: Text(
              'รีเซ็ต',
              style: GoogleFonts.kanit(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'บันทึกการตั้งค่า',
                  style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFEB5757)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Color(0xFFEB5757), size: 18),
            const SizedBox(width: 8),
            Text(
              'ออกจากระบบ',
              style: GoogleFonts.kanit(
                color: const Color(0xFFEB5757),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
