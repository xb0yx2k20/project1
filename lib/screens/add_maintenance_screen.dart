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
      appBar: AppBar(title: const Text('Добавить ТО')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedServiceId,
                items: _services
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s['id'] as String,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(s['name'] as String)),
                            if (s['averagePrice'] != null)
                              Text('${s['averagePrice']} ₽',
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedServiceId = val),
                decoration: const InputDecoration(labelText: 'Вид услуги (ТО)'),
                validator: (v) => v == null ? 'Выберите услугу' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Пробег (км)'),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? 'Введите корректный пробег'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Дата'),
                subtitle: Text('${_date.day.toString().padLeft(2, '0')}.'
                    '${_date.month.toString().padLeft(2, '0')}.${_date.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
