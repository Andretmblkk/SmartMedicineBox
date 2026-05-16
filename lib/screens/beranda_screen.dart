import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine_schedule.dart';
import '../services/firebase_schedule_service.dart';
import '../services/medicine_stock_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medicine_schedule_card.dart';
import 'tambah_jadwal_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen>
    with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  String _userName = '';
  final TextEditingController _nameController = TextEditingController();
  final List<MedicineSchedule> _todaySchedule = [];
  Timer? _stockSyncTimer;

  @override
  void initState() {
    super.initState();
    _nameController.text = _userName;
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.requestPermissions();
    _loadSchedule().then((_) {
      if (!mounted) return;
      _processDueSchedules();
      _startStockSyncTimer();
      if (_userName.isEmpty) {
        Future.delayed(Duration.zero, _showNameDialog);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stockSyncTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processDueSchedules();
    }
  }

  void _showNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Selamat Datang!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Silakan masukkan nama Anda untuk memulai.'),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nama Anda',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;

              setState(() {
                _userName = _nameController.text.trim();
              });
              _saveUserName();
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = prefs.getString('today_schedule');
    final savedName = prefs.getString('user_name');

    if (!mounted) return;

    if (scheduleJson != null && scheduleJson.isNotEmpty) {
      final decoded = jsonDecode(scheduleJson) as List<dynamic>;
      setState(() {
        _todaySchedule
          ..clear()
          ..addAll(
            decoded.map((item) {
              return MedicineSchedule.fromJson(Map<String, dynamic>.from(item));
            }),
          );
        _normalizeSharedMedicineStocks();
      });
    }
    if (savedName != null && savedName.isNotEmpty) {
      setState(() {
        _userName = savedName;
        _nameController.text = _userName;
      });
    }
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = MedicineStockService.instance.updateSchedules(
      _todaySchedule,
    );

    await prefs.setString('today_schedule', jsonEncode(scheduleJson));
    await prefs.setString('user_name', _userName);
    await FirebaseScheduleService.instance.saveSchedule(scheduleJson);
  }

  Future<void> _saveUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
  }

  void _normalizeSharedMedicineStocks() {
    final stockByMedicine = <String, int>{};
    final boxByMedicine = <String, int>{};
    final typeByMedicine = <String, String>{};

    for (final schedule in _todaySchedule) {
      final key = schedule.medicineKey;
      final currentStock = stockByMedicine[key];
      if (currentStock == null || schedule.remainingStock > currentStock) {
        stockByMedicine[key] = schedule.remainingStock;
      }
      boxByMedicine.putIfAbsent(key, () => schedule.medicineBox);
      typeByMedicine.putIfAbsent(key, () => schedule.type);
    }

    for (var i = 0; i < _todaySchedule.length; i++) {
      final schedule = _todaySchedule[i];
      _todaySchedule[i] = schedule.copyWith(
        remainingStock: stockByMedicine[schedule.medicineKey],
        medicineBox: boxByMedicine[schedule.medicineKey],
        type: typeByMedicine[schedule.medicineKey],
      );
    }
  }

  int get _totalCount => _todaySchedule.length;

  void _startStockSyncTimer() {
    _stockSyncTimer?.cancel();
    _stockSyncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _processDueSchedules(),
    );
  }

  Future<void> _processDueSchedules() async {
    if (_todaySchedule.isEmpty) return;

    final now = DateTime.now();
    final today = _formatDate(now);
    final nowMinutes = now.hour * 60 + now.minute;
    var updatedSchedules = List<MedicineSchedule>.from(_todaySchedule)
      ..sort((a, b) {
        return _scheduleTimeMinutes(a.time).compareTo(
          _scheduleTimeMinutes(b.time),
        );
      });
    var changed = false;

    for (final schedule in List<MedicineSchedule>.from(updatedSchedules)) {
      while (true) {
        final currentSchedule = updatedSchedules
            .cast<MedicineSchedule?>()
            .firstWhere(
              (item) => item?.id == schedule.id,
              orElse: () => null,
            );
        if (currentSchedule == null) break;

        final nextStockDate = _nextStockUpdateDate(currentSchedule);
        if (nextStockDate == null || nextStockDate.isAfter(now)) break;
        if (_isSameDate(nextStockDate, now) &&
            _scheduleTimeMinutes(currentSchedule.time) > nowMinutes) {
          break;
        }

        updatedSchedules = await MedicineStockService.instance.reduceStock(
          schedules: updatedSchedules,
          selectedSchedule: currentSchedule,
          stockUpdateDate: _formatDate(nextStockDate),
        );
        changed = true;
      }
    }

    if (!changed || !mounted) return;

    setState(() {
      _todaySchedule
        ..clear()
        ..addAll(updatedSchedules);
    });
    await _saveSchedule();
  }

  int _scheduleTimeMinutes(String value) {
    final text = value.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2})[:.](\d{2})\s*(AM|PM)?').firstMatch(text);
    if (match == null) return 24 * 60;

    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final meridiem = match.group(3);
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  DateTime? _nextStockUpdateDate(MedicineSchedule schedule) {
    final lastDate = _parseDate(schedule.lastStockUpdateDate);
    if (lastDate == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    return lastDate.add(const Duration(days: 1));
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(child: _buildCurrentView()),
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
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildReminderSummaryCard()),
          SliverToBoxAdapter(child: _buildMainMenuGrid()),
          SliverToBoxAdapter(child: _buildAlertSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jadwal Obat Hari Ini',
                    style: AppTheme.heading3(context),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentNavIndex = 1),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildScheduleCard(index),
                  );
                }, childCount: _todaySchedule.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(int index) {
    final schedule = _todaySchedule[index];
    return MedicineScheduleCard(
      medicineName: schedule.name,
      dosage: schedule.dosageLabel,
      time: schedule.time,
      type: schedule.type,
      medicineBox: schedule.medicineBox,
      remainingStock: schedule.remainingStock,
    );
  }

  Widget _buildHeader() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';
    final greetingName = _userName.trim().isEmpty
        ? ''
        : ', ${_userName.trim().split(' ')[0]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo$greetingName!',
                  style: AppTheme.heading2(context),
                ),
                Text(
                  'Jangan lupa minum obat tepat waktu ya.',
                  style: AppTheme.caption(context),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showTodayScheduleSheet,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  void _showTodayScheduleSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jadwal Obat Hari Ini', style: AppTheme.heading3(context)),
                const SizedBox(height: 12),
                if (_todaySchedule.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada jadwal obat.',
                        style: AppTheme.caption(context),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _todaySchedule.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final schedule = _todaySchedule[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          title: Text(
                            schedule.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${schedule.time} - Kotak ${schedule.medicineBox}',
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReminderSummaryCard() {
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
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pengingat Aktif',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Anda memiliki $_totalCount jadwal pengingat obat hari ini.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Notifikasi akan berulang setiap hari sampai stok habis.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuGrid() {
    final menuItems = [
      {
        'icon': Icons.add_box_rounded,
        'label': 'Tambah Obat',
        'color': Colors.blue,
        'action': _navigateToAdd,
      },
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
                    color: (menuItems[index]['color'] as Color).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    menuItems[index]['icon'] as IconData,
                    color: menuItems[index]['color'] as Color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                menuItems[index]['label'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
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

    final hasLowStock = _todaySchedule.any(
      (schedule) => schedule.remainingStock <= 3,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasLowStock
              ? AppTheme.warning.withValues(alpha: 0.08)
              : Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLowStock
                ? AppTheme.warning.withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasLowStock
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: hasLowStock ? AppTheme.warning : AppTheme.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasLowStock
                    ? 'Obat hampir habis. Segera siapkan stok obat kembali.'
                    : 'Pengingat obat aktif. Stok akan berkurang otomatis sesuai jadwal.',
                style: TextStyle(
                  color: hasLowStock ? Colors.orange[900] : Colors.blue[900],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
            const Text(
              'Belum ada jadwal obat hari ini',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex > 2 ? 0 : _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahJadwalScreen(
          existingSchedules: List<MedicineSchedule>.from(_todaySchedule),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      if (result is List<MedicineSchedule>) {
        _todaySchedule.addAll(result);
      } else if (result is List) {
        _todaySchedule.addAll(
          result.map((item) {
            if (item is MedicineSchedule) return item;
            return MedicineSchedule.fromJson(Map<String, dynamic>.from(item));
          }),
        );
      } else if (result is MedicineSchedule) {
        _todaySchedule.add(result);
      } else if (result is Map) {
        _todaySchedule.add(
          MedicineSchedule.fromJson(Map<String, dynamic>.from(result)),
        );
      }
      _normalizeSharedMedicineStocks();
    });
    await _saveSchedule();
  }

  Widget _buildJadwalView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Semua Jadwal Obat', style: AppTheme.heading2(context)),
          ),
        ),
        if (_todaySchedule.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScheduleCard(index),
                );
              }, childCount: _todaySchedule.length),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilView() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil Pengguna', style: AppTheme.heading2(context)),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Nama Lengkap', style: AppTheme.caption(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Nama pengguna',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfileName,
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengguna tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _userName = newName);
    await _saveUserName();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nama pengguna berhasil diperbarui.')),
    );
  }
}
