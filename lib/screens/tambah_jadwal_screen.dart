import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medicine_schedule.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class TambahJadwalScreen extends StatefulWidget {
  final List<MedicineSchedule> existingSchedules;

  const TambahJadwalScreen({super.key, this.existingSchedules = const []});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _nameFocusNode = FocusNode();

  String _selectedType = 'tablet';
  String _mealInstruction = 'Sesudah Makan';
  int? _selectedMedicineBox;

  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  final List<TextEditingController> _doseControllers = [
    TextEditingController(text: '1'),
  ];

  final List<Map<String, dynamic>> _medicineTypes = [
    {
      'id': 'tablet',
      'label': 'Tablet',
      'icon': Icons.medication_liquid_rounded,
    },
    {'id': 'capsule', 'label': 'Kapsul', 'icon': Icons.medication_rounded},
  ];

  final List<int> _medicineBoxes = [1, 2, 3, 4, 5, 6];

  final List<String> _mealOptions = [
    'Sebelum Makan',
    'Sesudah Makan',
    'Bersamaan Makan',
    'Bebas',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _nameFocusNode.dispose();
    for (final controller in _doseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTime() {
    setState(() {
      _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
      _doseControllers.add(TextEditingController(text: '1'));
    });
  }

  void _removeTime(int index) {
    if (_selectedTimes.length <= 1) return;

    setState(() {
      _selectedTimes.removeAt(index);
      _doseControllers[index].dispose();
      _doseControllers.removeAt(index);
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null) {
      setState(() => _selectedTimes[index] = picked);
    }
  }

  Future<void> _saveJadwal() async {
    if (!_formKey.currentState!.validate()) return;

    final medicineName = _nameController.text.trim();
    final existingMedicine = _findExistingMedicine(medicineName);
    final addedStock = int.parse(_stockController.text);
    final initialStock = (existingMedicine?.remainingStock ?? 0) + addedStock;
    final newSchedules = <MedicineSchedule>[];
    final formattedTimes = _selectedTimes
        .map((time) => time.format(context))
        .toList();

    try {
      for (var i = 0; i < _selectedTimes.length; i++) {
        final notificationId = math.Random().nextInt(100000);
        final dose = int.parse(_doseControllers[i].text);

        await NotificationService.instance.scheduleNotification(
          id: notificationId,
          title: 'Waktunya minum obat!',
          body:
              'Jangan lupa minum $medicineName ($dose butir) dari Kotak $_selectedMedicineBox. $_mealInstruction.',
          hour: _selectedTimes[i].hour,
          minute: _selectedTimes[i].minute,
        );

        newSchedules.add(
          MedicineSchedule.create(
            name: _nameController.text.trim(),
            dose: dose,
            remainingStock: initialStock,
            mealRule: _mealInstruction,
            time: formattedTimes[i],
            type: _selectedType,
            medicineBox: _selectedMedicineBox!,
            notificationId: notificationId,
            lastStockUpdateDate: _isTimeAlreadyPassed(_selectedTimes[i])
                ? _formatDate(DateTime.now())
                : null,
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, newSchedules);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal pengingat berhasil disimpan!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menjadwalkan: $e')));
    }
  }

  String? _validatePositiveNumber(String? value, String label) {
    final number = int.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return '$label harus lebih dari 0';
    }
    return null;
  }

  String? _validateDose(String? value) {
    final numberError = _validatePositiveNumber(value, 'Dosis');
    if (numberError != null) return numberError;

    final stock = _effectiveStock();
    final dose = int.parse(value!);
    if (stock != null && dose > stock) {
      return 'Dosis tidak boleh melebihi stok';
    }
    return null;
  }

  void _applyExistingMedicine(String medicineName) {
    final existingMedicine = _findExistingMedicine(medicineName);
    if (existingMedicine == null) return;

    setState(() {
      _selectedType = existingMedicine.type;
      _selectedMedicineBox = existingMedicine.medicineBox;
      _stockController.clear();
    });
  }

  MedicineSchedule? _findExistingMedicine(String medicineName) {
    final medicineKey = MedicineSchedule.normalizeMedicineName(medicineName);
    if (medicineKey.isEmpty) return null;

    for (final schedule in widget.existingSchedules) {
      if (schedule.medicineKey == medicineKey) return schedule;
    }
    return null;
  }

  bool _isExistingMedicine(String medicineName) {
    return _findExistingMedicine(medicineName) != null;
  }

  bool _isBoxUnavailableForSelection(int box) {
    final existingMedicine = _findExistingMedicine(_nameController.text);
    if (existingMedicine != null) {
      return box != existingMedicine.medicineBox;
    }

    return widget.existingSchedules.any((schedule) {
      return schedule.medicineBox == box &&
          schedule.medicineKey !=
              MedicineSchedule.normalizeMedicineName(_nameController.text);
    });
  }

  int? _effectiveStock() {
    final existingMedicine = _findExistingMedicine(_nameController.text);
    final addedStock = int.tryParse(_stockController.text);
    if (existingMedicine == null) return addedStock;
    if (addedStock == null) return existingMedicine.remainingStock;
    return existingMedicine.remainingStock + addedStock;
  }

  bool _isTimeAlreadyPassed(TimeOfDay time) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final selectedMinutes = time.hour * 60 + time.minute;
    return selectedMinutes <= nowMinutes;
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Tambah Pengingat Obat', style: AppTheme.heading3(context)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
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
              _buildInputLabel('Nama Obat'),
              _buildMedicineNameAutocomplete(),
              const SizedBox(height: 24),
              _buildInputLabel(
                _isExistingMedicine(_nameController.text)
                    ? 'Tambah Stok Obat'
                    : 'Stok Awal Obat',
              ),
              _buildNumberField(
                controller: _stockController,
                hint: 'Contoh: 10',
                icon: Icons.inventory_2_rounded,
                validator: (value) =>
                    _validatePositiveNumber(value, 'Stok obat'),
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Jenis Obat'),
              _buildMedicineTypePicker(
                isLocked: _isExistingMedicine(_nameController.text),
              ),
              const SizedBox(height: 24),
              _buildInputLabel('Kotak Obat'),
              _buildMedicineBoxDropdown(),
              const SizedBox(height: 24),
              _buildInputLabel('Aturan Makan'),
              _buildMealPicker(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel('Waktu & Dosis'),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Tambah Waktu'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Simpan Pengingat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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

  Widget _buildMedicineNameAutocomplete() {
    final medicineNames = widget.existingSchedules
        .map((schedule) => schedule.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return RawAutocomplete<String>(
      textEditingController: _nameController,
      focusNode: _nameFocusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return medicineNames;
        return medicineNames.where((name) => name.toLowerCase().contains(query));
      },
      onSelected: _applyExistingMedicine,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nama obat wajib diisi'
              : null,
          onChanged: (value) {
            final existingMedicine = _findExistingMedicine(value);
            setState(() {
              if (existingMedicine != null) {
                _selectedType = existingMedicine.type;
                _selectedMedicineBox = existingMedicine.medicineBox;
              } else if (_isBoxUnavailableForSelection(
                _selectedMedicineBox ?? 0,
              )) {
                _selectedMedicineBox = null;
              }
            });
          },
          decoration: _inputDecoration(
            hint: 'Pilih atau ketik nama obat baru',
            icon: Icons.medication_rounded,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
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
    );
  }

  Widget _buildMedicineTypePicker({required bool isLocked}) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _medicineTypes.length,
        itemBuilder: (context, index) {
          final type = _medicineTypes[index];
          final isSelected = _selectedType == type['id'];
          return GestureDetector(
            onTap: isLocked
                ? null
                : () => setState(() => _selectedType = type['id'] as String),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicineBoxDropdown() {
    return DropdownButtonFormField<int>(
      key: ValueKey('medicine-box-${_selectedMedicineBox ?? 'empty'}'),
      initialValue: _selectedMedicineBox,
      validator: (value) {
        if (value == null || value < 1 || value > 6) {
          return 'Kotak obat wajib dipilih';
        }
        final existingMedicine = _findExistingMedicine(_nameController.text);
        if (existingMedicine != null && value != existingMedicine.medicineBox) {
          return 'Obat ini sudah memakai Kotak ${existingMedicine.medicineBox}';
        }
        if (_isBoxUnavailableForSelection(value)) {
          return 'Kotak $value sudah dipakai obat lain';
        }
        return null;
      },
      decoration: _inputDecoration(
        hint: 'Pilih kotak obat',
        icon: Icons.inventory_rounded,
      ),
      items: _medicineBoxes.map((box) {
        final disabled = _isBoxUnavailableForSelection(box);
        final label = disabled ? 'Kotak $box (terpakai)' : 'Kotak $box';
        return DropdownMenuItem<int>(
          value: box,
          enabled: !disabled,
          child: Text(
            label,
            style: TextStyle(color: disabled ? Colors.grey : Colors.black87),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedMedicineBox = value);
      },
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
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _selectedTimes[index].format(context),
                              style: AppTheme.bodyBold(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedTimes.length > 1)
                    IconButton(
                      onPressed: () => _removeTime(index),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _doseControllers[index],
                validator: _validateDose,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Dosis per minum (Contoh: 1 / 2)',
                  prefixIcon: const Icon(
                    Icons.science_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
