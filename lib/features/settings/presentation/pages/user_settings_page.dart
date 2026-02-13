import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/data/services/device_service.dart';
import 'package:flutter_application_1/features/settings/data/models/user_setting_response.dart';
import 'package:flutter_application_1/features/settings/data/services/user_setting_service.dart';
import 'package:google_fonts/google_fonts.dart';

class UserSettingsPage extends StatefulWidget {
  final VoidCallback onBack;

  const UserSettingsPage({super.key, required this.onBack});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final UserSettingService _service = UserSettingService();
  bool _isLoading = true;
  UserSettingOverview? _data;
  String? _currentDeviceId;

  // Local state for notification settings
  bool _notificationsEnabled = false;
  String _defaultNotifyTime = "00:00:00";
  int _defaultRemindDaysBefore = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final deviceKey = await DeviceService.getOrCreateDeviceId();

      final data = await _service.fetchUserSettings();
      setState(() {
        _data = data;
        _currentDeviceId = deviceKey;
        _notificationsEnabled = data.userSetting.notificationsEnabled;
        _defaultNotifyTime = data.userSetting.defaultNotifyTime;
        _defaultRemindDaysBefore = data.userSetting.defaultRemindDaysBefore;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _service.updateNotificationSettings(
        enabled: _notificationsEnabled,
        time: _defaultNotifyTime,
        daysBefore: _defaultRemindDaysBefore,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
      await _loadSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Device', style: GoogleFonts.kanit()),
        content: Text(
          'Are you sure you want to remove this device?',
          style: GoogleFonts.kanit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _service.deleteDevice(deviceId);
        await _loadSettings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting device: $e')));
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
      setState(() {
        _defaultNotifyTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: widget.onBack,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings,
                color: Color(0xFF27AE60),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Manage your preferences and configurations',
                  style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildNotificationSection(),
                      const SizedBox(height: 16),
                      if (_data != null) _buildDeviceSection(_data!.devices),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
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

  Widget _buildNotificationSection() {
    return _buildCard(
      children: [
        _buildSectionHeader(
          Icons.notifications_none,
          'Notifications',
          'Configure how and when you receive reminders about upcoming payments.',
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
                      'Enable Notifications',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Receive alerts before your payment due dates',
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
                activeColor: const Color(0xFF2ECC71),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Default Notification Time',
          style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          'Set the time of day you want to receive your reminders.',
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
          'Days Before Due Date',
          style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          'How many days in advance should we notify you?',
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _defaultRemindDaysBefore,
              isExpanded: true,
              items: List.generate(7, (index) => index + 1).map((val) {
                return DropdownMenuItem<int>(
                  value: val,
                  child: Text(
                    '$val days before',
                    style: GoogleFonts.kanit(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _defaultRemindDaysBefore = val);
              },
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
                  'Devices',
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
                '${devices.length} devices',
                style: GoogleFonts.kanit(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Manage the devices that are currently signed in to your account.',
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 16),
        ...devices.map((device) => _buildDeviceItem(device)).toList(),
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
                          'This device',
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
                      'Bangkok, Thailand',
                      size: 12,
                    ),
                    _buildInfoItem(Icons.access_time, 'Active now', size: 12),
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
        Text(
          label,
          style: GoogleFonts.kanit(fontSize: size, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _loadSettings(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            child: Text(
              'Reset',
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
                  'Save Settings',
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
}
