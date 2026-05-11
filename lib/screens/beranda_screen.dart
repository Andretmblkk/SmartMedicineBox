import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'tambah_jadwal_screen.dart';
import '../widgets/medicine_schedule_card.dart';
import '../widgets/medicine_schedule_card.dart';
import '../widgets/quick_stat_card.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/firebase_schedule_service.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  int _currentNavIndex = 0;
  String _userName = 'Ahmad Rizki';
  final TextEditingController _nameController = TextEditingController();
  final List<Map<String, dynamic>> _todaySchedule = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = _userName;
    NotificationService.instance.requestPermissions();
    _loadSchedule().then((_) {
      if (_userName == 'isi nama Anda' || _userName.isEmpty) {
        Future.delayed(Duration.zero, () => _showNameDialog());
      }
    });
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Selamat Datang!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Silakan masukkan nama Anda untuk memulai."),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Nama Anda",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                setState(() {
                  _userName = _nameController.text;
                });
                _saveSchedule();
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final String? scheduleJson = prefs.getString('today_schedule');
    
    if (!mounted) return;

    if (scheduleJson != null) {
      final List<dynamic> decoded = jsonDecode(scheduleJson);
      setState(() {
        _todaySchedule.clear();
        for (var item in decoded) {
          _todaySchedule.add(Map<String, dynamic>.from(item));
        }
      });
    }
    final String? savedName = prefs.getString('user_name');
    if (savedName != null && savedName.isNotEmpty) {
      setState(() {
        _userName = savedName;
        _nameController.text = _userName;
      });
    }
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_schedule', jsonEncode(_todaySchedule));
    await prefs.setString('user_name', _userName);
    
    // Simpan juga ke Firebase untuk dibaca oleh sensor
    await FirebaseScheduleService.instance.saveSchedule(_todaySchedule);
  }

  int get _takenCount => _todaySchedule.where((m) => m['taken'] == true).length;
  int get _totalCount => _todaySchedule.length;
  double get _adherencePercentage =>
      _totalCount > 0 ? (_takenCount / _totalCount) * 100 : 0;

  void _removeMedicine(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _todaySchedule.removeAt(index);
    });
    _saveSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: _buildCurrentView(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentNavIndex) {
      case 1:
        return _buildJadwalView();
      case 2:
        return _buildProfilView();
      case 0:
      default:
        return _buildBerandaView();
    }
  }

  Widget _buildBerandaView() {
    return RefreshIndicator(
      onRefresh: _loadSchedule,
      color: AppTheme.primaryBlue,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header User ──
          SliverToBoxAdapter(child: _buildHeader()),
          
          // ── Card Monitoring Real-time ──
          SliverToBoxAdapter(child: _buildMonitoringCard()),
          
          // ── Grid Menu Utama ──
          SliverToBoxAdapter(child: _buildMainMenuGrid()),
          
          // ── Section Notifikasi / Alert ──
          SliverToBoxAdapter(child: _buildAlertSection()),
          
          // ── Daftar Jadwal Hari Ini ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Jadwal Obat Hari Ini", style: AppTheme.heading3(context)),
                  TextButton(
                    onPressed: () => setState(() => _currentNavIndex = 1),
                    child: const Text("Lihat Semua", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          
          if (_todaySchedule.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MedicineScheduleCard(
                        medicineName: _todaySchedule[index]['name'],
                        dosage: _todaySchedule[index]['dosage'],
                        time: _todaySchedule[index]['time'],
                        type: _todaySchedule[index]['type'],
                        isTaken: false,
                        onTap: () => _removeMedicine(index),
                      ),
                    );
                  },
                  childCount: _todaySchedule.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Halo, ${_userName.split(' ')[0]}! 👋", style: AppTheme.heading2(context)),
                Text("Jangan lupa minum obat tepat waktu ya.", style: AppTheme.caption(context)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Notifikasi aksi
            },
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(context).copyWith(
          gradient: const LinearGradient(
            colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Pengingat Aktif",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Anda memiliki $_totalCount jadwal pengingat obat hari ini.",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Tetap sehat dengan minum obat tepat waktu.",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuGrid() {
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.add_box_rounded, 'label': 'Tambah Obat', 'color': Colors.blue, 'action': () => _navigateToAdd()},
      {'icon': Icons.history_rounded, 'label': 'Riwayat', 'color': Colors.orange, 'action': () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Riwayat akan segera hadir!")));
      }},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              GestureDetector(
                onTap: menuItems[index]['action'] as VoidCallback,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (menuItems[index]['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(menuItems[index]['icon'] as IconData, color: menuItems[index]['color'] as Color, size: 28),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                menuItems[index]['label'] as String,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertSection() {
    if (_totalCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Semua pengingat telah dijadwalkan dengan benar. Pastikan notifikasi Anda aktif.",
                style: TextStyle(color: Colors.blue[900], fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.medication_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Belum ada jadwal obat hari ini", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TambahJadwalScreen()),
    );
    if (result != null) {
      if (result is List) {
        setState(() {
          for (var item in result) {
            _todaySchedule.add(Map<String, dynamic>.from(item));
          }
        });
      } else if (result is Map) {
        setState(() {
          _todaySchedule.add(Map<String, dynamic>.from(result));
        });
      }
      _saveSchedule();
    }
  }

  Widget _buildJadwalView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Semua Jadwal Obat", style: AppTheme.heading2(context)),
          ),
        ),
        if (_todaySchedule.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicineScheduleCard(
                      medicineName: _todaySchedule[index]['name'],
                      dosage: _todaySchedule[index]['dosage'],
                      time: _todaySchedule[index]['time'],
                      type: _todaySchedule[index]['type'],
                      isTaken: false,
                      onTap: () => _removeMedicine(index),
                    ),
                  );
                },
                childCount: _todaySchedule.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Profil Pengguna", style: AppTheme.heading2(context)),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(_userName[0], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 32),
          Text("Nama Lengkap", style: AppTheme.caption(context)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Text(_userName, style: AppTheme.bodyBold(context)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Logika logout atau ganti nama
            },
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }
}
