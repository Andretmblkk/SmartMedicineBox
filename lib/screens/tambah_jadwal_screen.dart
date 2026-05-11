import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'dart:math' as math;

class TambahJadwalScreen extends StatefulWidget {
  const TambahJadwalScreen({super.key});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedType = 'capsule';
  String _mealInstruction = 'Sesudah Makan';
  
  // Multi-time scheduling
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  List<TextEditingController> _dosageControllers = [TextEditingController(text: '1 Butir')];

  final List<Map<String, dynamic>> _medicineTypes = [
    {'id': 'capsule', 'label': 'Kapsul', 'icon': Icons.medication_rounded},
    {'id': 'tablet', 'label': 'Tablet', 'icon': Icons.medication_liquid_rounded},
    {'id': 'syrup', 'label': 'Sirup', 'icon': Icons.local_drink_rounded},
    {'id': 'injection', 'label': 'Suntikan', 'icon': Icons.vaccines_rounded},
  ];

  final List<String> _mealOptions = ['Sebelum Makan', 'Sesudah Makan', 'Bersamaan Makan', 'Bebas'];

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _dosageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTime() {
    setState(() {
      _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
      _dosageControllers.add(TextEditingController(text: '1 Butir'));
    });
  }

  void _removeTime(int index) {
    if (_selectedTimes.length > 1) {
      setState(() {
        _selectedTimes.removeAt(index);
        _dosageControllers[index].dispose();
        _dosageControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null) {
      setState(() => _selectedTimes[index] = picked);
    }
  }

  void _saveJadwal() async {
    if (_formKey.currentState!.validate()) {
      final List<Map<String, dynamic>> newSchedules = [];
      
      try {
        for (int i = 0; i < _selectedTimes.length; i++) {
          final int notificationId = math.Random().nextInt(100000);
          
          await NotificationService.instance.scheduleNotification(
            id: notificationId,
            title: "Waktunya minum obat! 💊",
            body: "Jangan lupa minum ${_nameController.text} (${_dosageControllers[i].text}) Anda. $_mealInstruction.",
            hour: _selectedTimes[i].hour,
            minute: _selectedTimes[i].minute,
          );

          newSchedules.add({
            'name': _nameController.text,
            'dosage': "${_dosageControllers[i].text} • $_mealInstruction",
            'time': _selectedTimes[i].format(context),
            'type': _selectedType,
            'taken': false,
          });
        }

        if (mounted) {
          Navigator.pop(context, newSchedules);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Jadwal pengingat berhasil disimpan!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menjadwalkan: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Tambah Pengingat Obat", style: AppTheme.heading3(context)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel("Nama Obat"),
              _buildTextField(
                controller: _nameController,
                hint: "Contoh: Paracetamol",
                icon: Icons.medication_rounded,
                validator: (v) => v!.isEmpty ? "Nama obat wajib diisi" : null,
              ),
              const SizedBox(height: 24),
              
              _buildInputLabel("Jenis Obat"),
              _buildMedicineTypePicker(),
              const SizedBox(height: 24),
              
              _buildInputLabel("Aturan Makan"),
              _buildMealPicker(),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel("Waktu & Dosis"),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text("Tambah Waktu"),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTimeAndDosageList(),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveJadwal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Simpan Pengingat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: AppTheme.bodyBold(context)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildMedicineTypePicker() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _medicineTypes.length,
        itemBuilder: (context, index) {
          final type = _medicineTypes[index];
          final isSelected = _selectedType == type['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type['id'] as String),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type['icon'] as IconData, color: isSelected ? Colors.white : Colors.grey[600], size: 28),
                  const SizedBox(height: 4),
                  Text(type['label'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealPicker() {
    return Wrap(
      spacing: 10,
      children: _mealOptions.map((option) {
        final isSelected = _mealInstruction == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _mealInstruction = option);
          },
          selectedColor: AppTheme.primaryBlue,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          backgroundColor: Colors.grey[100],
        );
      }).toList(),
    );
  }

  Widget _buildTimeAndDosageList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedTimes.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: AppTheme.primaryBlue, size: 20),
                            const SizedBox(width: 10),
                            Text(_selectedTimes[index].format(context), style: AppTheme.bodyBold(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedTimes.length > 1)
                    IconButton(
                      onPressed: () => _removeTime(index),
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dosageControllers[index],
                decoration: InputDecoration(
                  hintText: "Dosis (Contoh: 1 Butir / 5ml)",
                  prefixIcon: const Icon(Icons.science_rounded, color: AppTheme.primaryBlue, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
