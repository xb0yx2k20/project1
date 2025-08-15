import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/maintenance_record.dart';
import '../models/vehicle_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'add_vehicle_screen.dart';
import 'add_maintenance_screen.dart';

class VehicleHomeScreen extends StatefulWidget {
  const VehicleHomeScreen({super.key});

  @override
  State<VehicleHomeScreen> createState() => _VehicleHomeScreenState();
}

class _VehicleHomeScreenState extends State<VehicleHomeScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои автомобили'),
        actions: [
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: _firestore.getUserVehicles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final vehicles = snapshot.data ?? [];

          if (vehicles.isEmpty) {
            return _EmptyState(onAddVehicle: _goToAddVehicle);
          }

          _selectedVehicleId ??= vehicles.first.id;
          final selected =
              vehicles.firstWhere((v) => v.id == _selectedVehicleId);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VehicleSwitcher(
                vehicles: vehicles,
                selectedVehicleId: _selectedVehicleId!,
                onSelected: (id) => setState(() => _selectedVehicleId = id),
                onAddVehicle: _goToAddVehicle,
                onDeleteVehicle: _showDeleteVehicleDialog,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${selected.make} ${selected.model} • ${selected.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MaintenanceRecord>>(
                  stream: _firestore.getVehicleMaintenance(_selectedVehicleId!),
                  builder: (context, recordsSnap) {
                    if (recordsSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final records = recordsSnap.data ?? [];
                    if (records.isEmpty) {
                      return const _EmptyMaintenance();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = records[index];
                        return Dismissible(
                          key: Key(r.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Colors.red,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Удалить запись ТО?'),
                                content: Text(
                                    'ТО "${r.type}" будет удалено безвозвратно.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            _firestore.deleteMaintenanceRecord(
                                _selectedVehicleId!, r.id);
                          },
                          child: ListTile(
                            leading: const Icon(Icons.build_circle_outlined),
                            title: Text(r.type),
                            subtitle: Text(
                              'Пробег: ${r.mileage} км • ${DateFormat('dd.MM.yyyy').format(r.date)}',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedVehicleId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _goToAddMaintenance(_selectedVehicleId!),
              icon: const Icon(Icons.add),
              label: const Text('Добавить ТО'),
            ),
    );
  }

  Future<void> _goToAddVehicle() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );
  }

  Future<void> _goToAddMaintenance(String vehicleId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMaintenanceScreen(vehicleId: vehicleId),
      ),
    );
  }

  Future<void> _showDeleteVehicleDialog(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text(
          'Автомобиль "${vehicle.make} ${vehicle.model}" и все записи ТО будут удалены безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _firestore.deleteVehicle(vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${vehicle.make} ${vehicle.model} удален')),
        );
      }
    }
  }
}

class _VehicleSwitcher extends StatelessWidget {
  const _VehicleSwitcher({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
    required this.onAddVehicle,
    required this.onDeleteVehicle,
  });

  final List<Vehicle> vehicles;
  final String selectedVehicleId;
  final ValueChanged<String> onSelected;
  final Future<void> Function() onAddVehicle;
  final Future<void> Function(Vehicle) onDeleteVehicle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final v in vehicles)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ChoiceChip(
                    label: Text('${v.make} ${v.model}'),
                    selected: v.id == selectedVehicleId,
                    onSelected: (_) => onSelected(v.id),
                  ),
                  if (vehicles.length > 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => onDeleteVehicle(v),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Добавить авто'),
            onPressed: onAddVehicle,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddVehicle});

  final Future<void> Function() onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_filled, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Нет добавленных автомобилей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте автомобиль, чтобы видеть историю ТО и быстро вносить новые записи.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Добавить автомобиль'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMaintenance extends StatelessWidget {
  const _EmptyMaintenance();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history_toggle_off, size: 56),
            SizedBox(height: 12),
            Text('Пока нет записей ТО'),
            SizedBox(height: 4),
            Text('Нажмите «Добавить ТО», чтобы создать первую запись'),
          ],
        ),
      ),
    );
  }
}
