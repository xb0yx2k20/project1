import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../services/firestore_service.dart';

class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  DateTime _date = DateTime.now();
  final _service = FirestoreService();

  // Services reference data
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _services = [];
  String? _selectedServiceId;

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final snapshot = await _db.collection('services').orderBy('name').get();
    var items = snapshot.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();

    // Seed defaults if empty
    if (items.isEmpty) {
      await _seedDefaultServices();
      final snap2 = await _db.collection('services').orderBy('name').get();
      items = snap2.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
    }

    setState(() {
      _services = items;
      if (_services.isNotEmpty) {
        _selectedServiceId = _services.first['id'] as String;
      }
    });
  }

  Future<void> _seedDefaultServices() async {
    final defaults = [
      {
        'name': 'Замена масла',
        'description': 'Замена моторного масла и фильтра',
        'averagePrice': 2500,
      },
      {
        'name': 'Замена тормозных колодок',
        'description': 'Передние и/или задние колодки',
        'averagePrice': 4500,
      },
      {
        'name': 'Диагностика двигателя',
        'description': 'Компьютерная диагностика',
        'averagePrice': 1500,
      },
      {
        'name': 'Замена воздушного фильтра',
        'description': 'Фильтр двигателя',
        'averagePrice': 900,
      },
      {
        'name': 'Замена свечей зажигания',
        'description': 'Комплект свечей',
        'averagePrice': 3200,
      },
    ];
    final batch = _db.batch();
    for (final s in defaults) {
      final ref = _db.collection('services').doc();
      batch.set(ref, s);
    }
    await batch.commit();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) return;
    final selected = _services.firstWhere((s) => s['id'] == _selectedServiceId);
    final record = MaintenanceRecord(
      id: '',
      type: (selected['name'] as String).trim(),
      mileage: int.parse(_mileageController.text.trim()),
      date: _date,
    );
    await _service.addMaintenanceRecord(widget.vehicleId, record);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Добавить ТО',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Новая запись ТО',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Заполните информацию о проведенном ТО',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedServiceId,
                items: _services
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s['id'] as String,
                        child: Text(
                          '${s['name']}${s['averagePrice'] != null ? ' (${s['averagePrice']} ₽)' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedServiceId = val),
                decoration: InputDecoration(
                  labelText: 'Вид услуги (ТО)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (v) => v == null ? 'Выберите услугу' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Пробег (км)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? 'Введите корректный пробег'
                    : null,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Дата',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_date.day.toString().padLeft(2, '0')}.'
                            '${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Изменить'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Сохранить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
