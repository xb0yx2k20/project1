import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedServiceCenterId;
  List<String> _selectedServiceIds = [];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _serviceCenters = [];
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Загружаем сервисные центры
    final serviceCentersSnapshot = await _db.collection('serviceCenters').get();
    final serviceCenters =
        serviceCentersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

    // Загружаем услуги
    final servicesSnapshot = await _db.collection('services').get();
    final services =
        servicesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

    setState(() {
      _serviceCenters = serviceCenters;
      _services = services;
      if (serviceCenters.isNotEmpty) {
        _selectedServiceCenterId = serviceCenters.first['id'];
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveRecord() async {
    if (_formKey.currentState!.validate() &&
        _selectedServiceCenterId != null &&
        _selectedServiceIds.isNotEmpty) {
      try {
        await _db.collection('maintenanceRecords').add({
          'serviceCenterID': _selectedServiceCenterId,
          'date': _selectedDate.toIso8601String(),
          'servicesPerformed': _selectedServiceIds,
          'cost': int.parse(_costController.text),
          'mileage': int.parse(_mileageController.text),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Запись успешно добавлена')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при добавлении записи: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Добавить запись ТО")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Выбор сервисного центра
              DropdownButtonFormField<String>(
                value: _selectedServiceCenterId,
                decoration: const InputDecoration(labelText: "Сервисный центр"),
                items:
                    _serviceCenters.map((center) {
                      return DropdownMenuItem<String>(
                        value: center['id'] as String,
                        child: Text(center['name'] as String),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceCenterId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Выберите сервисный центр";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Выбор даты
              ListTile(
                title: const Text("Дата"),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Выбор услуг
              const Text("Выполненные услуги:", style: TextStyle(fontSize: 16)),
              ..._services.map(
                (service) => CheckboxListTile(
                  title: Text(service['name']),
                  subtitle: Text('${service['averagePrice']} ₽'),
                  value: _selectedServiceIds.contains(service['id']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedServiceIds.add(service['id']);
                      } else {
                        _selectedServiceIds.remove(service['id']);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Пробег
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Пробег (км)"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Введите пробег";
                  }
                  if (int.tryParse(value) == null) {
                    return "Введите корректное число";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Стоимость
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Стоимость (₽)"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Введите стоимость";
                  }
                  if (int.tryParse(value) == null) {
                    return "Введите корректное число";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Кнопка сохранения
              ElevatedButton(
                onPressed: _saveRecord,
                child: const Text("Сохранить"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    super.dispose();
  }
}
