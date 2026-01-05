import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildPersonalInfo(),
                _buildHealthInfo(),
                _buildEmergencyContacts(),
                _buildDeviceInfo(),
                _buildAppInfo(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.teal,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal,
                Colors.teal.shade700,
                Colors.teal.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Ad Soyad
                const Text(
                  'Ahmet Yılmaz',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Alt Bilgi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '68 yaş • Erkek',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      title: 'Kişisel Bilgiler',
      icon: Icons.person_outline,
      iconColor: Colors.blue,
      children: [
        _buildInfoRow(Icons.cake_outlined, 'Doğum Tarihi', '15 Mart 1956'),
        _buildInfoRow(Icons.bloodtype_outlined, 'Kan Grubu', 'A Rh+'),
        _buildInfoRow(Icons.height_outlined, 'Boy', '175 cm'),
        _buildInfoRow(Icons.monitor_weight_outlined, 'Kilo', '78 kg'),
      ],
    );
  }

  Widget _buildHealthInfo() {
    return _buildSection(
      title: 'Sağlık Bilgileri',
      icon: Icons.health_and_safety_outlined,
      iconColor: Colors.red,
      children: [
        _buildInfoRow(Icons.medication_outlined, 'İlaçlar', '2 düzenli ilaç'),
        _buildInfoRow(Icons.warning_amber_outlined, 'Alerjiler', 'Penisilin'),
        _buildInfoRow(Icons.local_hospital_outlined, 'Kronik Hastalıklar', 
                      'Hipertansiyon'),
        _buildInfoRow(Icons.medical_information_outlined, 'Kan Şekeri', 
                      'Normal (95 mg/dL)'),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    return _buildSection(
      title: 'Acil Durum İletişim',
      icon: Icons.emergency_outlined,
      iconColor: Colors.orange,
      children: [
        _buildContactRow(
          Icons.person,
          'Ayşe Yılmaz',
          'Kızı',
          '+90 555 123 4567',
        ),
        _buildContactRow(
          Icons.local_hospital,
          'Dr. Mehmet Demir',
          'Aile Hekimi',
          '+90 555 987 6543',
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Yeni Kişi Ekle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return _buildSection(
      title: 'Bağlı Cihazlar',
      icon: Icons.watch_outlined,
      iconColor: Colors.purple,
      children: [
        _buildDeviceRow(
          Icons.watch,
          'Smart Watch Pro',
          'Bağlı',
          Colors.green,
          'Son senkronizasyon: 2 dk önce',
        ),
        _buildDeviceRow(
          Icons.phone_android,
          'Samsung Galaxy A54',
          'Bağlı',
          Colors.green,
          'Ana cihaz',
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return _buildSection(
      title: 'Uygulama',
      icon: Icons.info_outline,
      iconColor: Colors.grey,
      children: [
        _buildInfoRow(Icons.verified_outlined, 'Versiyon', '1.0.0'),
        _buildInfoRow(Icons.update_outlined, 'Son Güncelleme', '5 Ocak 2026'),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Uygulamayı Paylaş',
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.star_outline,
          label: 'Değerlendir',
          color: Colors.amber,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.help_outline,
          label: 'Yardım & Destek',
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.privacy_tip_outlined,
          label: 'Gizlilik Politikası',
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String name,
    String relation,
    String phone,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  relation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone, color: Colors.green),
            tooltip: phone,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(
    IconData icon,
    String name,
    String status,
    Color statusColor,
    String detail,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.purple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}