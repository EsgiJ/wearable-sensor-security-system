import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';  
import '../providers/sensor_data_provider.dart';
import '../services/emergency_service.dart';
import '../services/localization_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minHeartRateController;
  late TextEditingController _maxHeartRateController;
  late TextEditingController _inactivityTimeController;
  late TextEditingController _caregiverNameController;
  late TextEditingController _caregiverPhoneController;
  
  late AnimationController _saveButtonController;
  bool _isTestingSMS = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SensorDataProvider>(context, listen: false);
    
    _minHeartRateController = TextEditingController(
      text: provider.minHeartRate.toInt().toString(),
    );
    _maxHeartRateController = TextEditingController(
      text: provider.maxHeartRate.toInt().toString(),
    );
    _inactivityTimeController = TextEditingController(
      text: provider.inactivityTimeMinutes.toString(),
    );
    _caregiverNameController = TextEditingController();
    _caregiverPhoneController = TextEditingController();
    
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _loadCaregiverInfo();
  }

  Future<void> _loadCaregiverInfo() async {
    final info = await EmergencyService.getCaregiverInfo();
    if (mounted) {
      setState(() {
        _caregiverNameController.text = info['name'] ?? '';
        _caregiverPhoneController.text = info['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _minHeartRateController.dispose();
    _maxHeartRateController.dispose();
    _inactivityTimeController.dispose();
    _caregiverNameController.dispose();
    _caregiverPhoneController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  void _saveSettings(LocalizationService loc) async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SensorDataProvider>(context, listen: false);
      
      provider.updateThresholds(
        minHR: double.parse(_minHeartRateController.text),
        maxHR: double.parse(_maxHeartRateController.text),
        inactivityTime: int.parse(_inactivityTimeController.text),
      );
      
      await EmergencyService.saveCaregiverInfo(
        name: _caregiverNameController.text.trim(),
        phone: _caregiverPhoneController.text.trim(),
      );
      
      _saveButtonController.forward().then((_) {
        _saveButtonController.reverse();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(loc.t('settings_saved_success')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _testSMS(LocalizationService loc) async {
    if (_caregiverPhoneController.text.trim().isEmpty) {
      _showSnackBar(loc.t('first_enter_phone'), Colors.orange);
      return;
    }

    setState(() => _isTestingSMS = true);

    try {
      await EmergencyService.testCaregiverContact(context);

      if (mounted) {
        _showSnackBar(loc.t('test_sms_sent'), Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${loc.t('error')}: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingSMS = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(loc),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeartRateSection(loc),
                  _buildInactivitySection(loc),
                  _buildCaregiverSection(loc),
                  _buildNotificationSection(loc),
                  _buildTestSection(loc),
                  _buildSaveButton(loc),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(LocalizationService loc) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          loc.t('settings'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue,
                Colors.blue.shade700,
                Colors.blue.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.t('system_settings'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loc.t('customize_preferences'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartRateSection(LocalizationService loc) {
    return _buildSection(
      title: loc.t('heart_rate_thresholds'),
      icon: Icons.favorite_rounded,
      iconColor: Colors.red,
      child: Column(
        children: [
          _buildTextField(
            loc: loc,
            controller: _minHeartRateController,
            label: loc.t('minimum_heart_rate'),
            icon: Icons.arrow_downward,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return loc.t('please_enter_value');
              }
              final number = int.tryParse(value);
              if (number == null || number < 30 || number > 100) {
                return '${loc.t('enter_value_between')} 30-100';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            loc: loc,
            controller: _maxHeartRateController,
            label: loc.t('maximum_heart_rate'),
            icon: Icons.arrow_upward,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return loc.t('please_enter_value');
              }
              final number = int.tryParse(value);
              if (number == null || number < 100 || number > 200) {
                return '${loc.t('enter_value_between')} 100-200';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildInfoBox(
            loc.t('hr_normal_info'),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInactivitySection(LocalizationService loc) {
    return _buildSection(
      title: loc.t('inactivity_detection'),
      icon: Icons.timer_rounded,
      iconColor: Colors.orange,
      child: Column(
        children: [
          _buildTextField(
            loc: loc,
            controller: _inactivityTimeController,
            label: loc.t('inactivity_timeout'),
            icon: Icons.schedule,
            keyboardType: TextInputType.number,
            helperText: loc.t('inactivity_timeout_help'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return loc.t('please_enter_value');
              }
              final number = int.tryParse(value);
              if (number == null || number < 5 || number > 120) {
                return '${loc.t('enter_value_between')} 5-120';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverSection(LocalizationService loc) {
    return _buildSection(
      title: loc.t('emergency_contact'),
      icon: Icons.contact_phone_rounded,
      iconColor: Colors.red,
      urgent: true,
      urgentLabel: loc.t('important'),
      child: Column(
        children: [
          _buildTextField(
            loc: loc,
            controller: _caregiverNameController,
            label: loc.t('caregiver_name'),
            icon: Icons.person,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            loc: loc,
            controller: _caregiverPhoneController,
            label: loc.t('phone_number'),
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            helperText: loc.t('phone_help'),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 10) {
                  return loc.t('enter_valid_phone');
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTestSMSButton(loc),
          const SizedBox(height: 12),
          _buildInfoBox(
            loc.t('emergency_warning'),
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(LocalizationService loc) {
    return _buildSection(
      title: loc.t('notification_settings'),
      icon: Icons.notifications_rounded,
      iconColor: Colors.purple,
      child: Column(
        children: [
          _buildSwitchTile(
            loc: loc,
            title: loc.t('fall_notifications'),
            subtitle: loc.t('fall_notif_desc'),
            value: true,
            icon: Icons.warning_rounded,
          ),
          _buildSwitchTile(
            loc: loc,
            title: loc.t('inactivity_notifications'),
            subtitle: loc.t('inactivity_notif_desc'),
            value: true,
            icon: Icons.timer_off_rounded,
          ),
          _buildSwitchTile(
            loc: loc,
            title: loc.t('heart_rate_notifications'),
            subtitle: loc.t('hr_notif_desc'),
            value: true,
            icon: Icons.favorite_rounded,
          ),
          _buildSwitchTile(
            loc: loc,
            title: loc.t('audio_alerts'),
            subtitle: loc.t('audio_alerts_desc'),
            value: true,
            icon: Icons.volume_up_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(LocalizationService loc) {
    return _buildSection(
      title: loc.t('test_mode'),
      icon: Icons.science_rounded,
      iconColor: Colors.teal,
      child: Column(
        children: [
          _buildInfoBox(
            loc.t('test_mode_info'),
            Colors.teal,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _startTestMode(loc),
              icon: const Icon(Icons.bug_report_rounded),
              label: Text(loc.t('start_test_mode')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    bool urgent = false,
    String? urgentLabel,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: urgent ? Border.all(color: iconColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (urgent && urgentLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      urgentLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required LocalizationService loc,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildSwitchTile({
    required LocalizationService loc,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32, top: 4),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        value: value,
        onChanged: (value) {},
        activeThumbColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSMSButton(LocalizationService loc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isTestingSMS ? null : () => _testSMS(loc),
        icon: _isTestingSMS
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(_isTestingSMS ? loc.t('sending') : loc.t('test_sms_send')),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(LocalizationService loc) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _saveButtonController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_saveButtonController.value * 0.05),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _saveSettings(loc),
                icon: const Icon(Icons.save_rounded, size: 24),
                label: Text(
                  loc.t('save_settings'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.blue.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startTestMode(LocalizationService loc) {
    final provider = Provider.of<SensorDataProvider>(context, listen: false);
    
    Future.delayed(Duration.zero, () {
      _generateTestData(provider, loc);
    });
    
    _showSnackBar(loc.t('test_mode_started'), Colors.orange);
  }

  void _generateTestData(SensorDataProvider provider, LocalizationService loc) {
    int count = 0;
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || count >= 10) {
        timer.cancel();
        if (mounted) {
          _showSnackBar(loc.t('test_mode_completed'), Colors.teal);
        }
        return;
      }
      
      double heartRate = 60 + (40 * (0.5 + 0.5 * (count % 10) / 10));
      double accX = -1 + 2 * ((count * 13) % 100) / 100;
      double accY = -1 + 2 * ((count * 17) % 100) / 100;
      double accZ = -1 + 2 * ((count * 19) % 100) / 100;
      
      provider.updateSensorData(
        heartRate: heartRate,
        accX: accX,
        accY: accY,
        accZ: accZ,
      );
      
      count++;
    });
  }
}