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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Мои автомобили',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout_outlined),
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
            return const Center(
              child: CircularProgressIndicator(),
            );
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
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selected.make} ${selected.model}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selected.year} • ${selected.vin.isNotEmpty ? 'VIN: ${selected.vin}' : 'VIN не указан'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MaintenanceRecord>>(
                  stream: _firestore.getVehicleMaintenance(_selectedVehicleId!),
                  builder: (context, recordsSnap) {
                    if (recordsSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final records = recordsSnap.data ?? [];
                    if (records.isEmpty) {
                      return const _EmptyMaintenance();
                    }

                    // Calculate grid layout based on screen size
                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = screenWidth > 800 ? 4 : 3;
                    final childAspectRatio = screenWidth > 800 ? 0.75 : 0.8;

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final r = records[index];
                          return _MaintenanceCard(
                            record: r,
                            onDelete: () => _firestore.deleteMaintenanceRecord(
                              _selectedVehicleId!,
                              r.id,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Vehicle>>(
        stream: _firestore.getUserVehicles(),
        builder: (context, snapshot) {
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty || _selectedVehicleId == null) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _goToAddMaintenance(_selectedVehicleId!),
            icon: const Icon(Icons.add),
            label: const Text('Добавить ТО'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          );
        },
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

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.record,
    required this.onDelete,
  });

  final MaintenanceRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить запись ТО?'),
            content: Text('ТО "${record.type}" будет удалено безвозвратно.'),
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
      },
      onDismissed: (direction) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.build_circle_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd.MM.yy').format(record.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                record.type,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${record.mileage} км',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final v in vehicles)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    ChoiceChip(
                      label: Text(
                        '${v.make} ${v.model}',
                        style: TextStyle(
                          fontWeight: v.id == selectedVehicleId
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      selected: v.id == selectedVehicleId,
                      onSelected: (_) => onSelected(v.id),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: v.id == selectedVehicleId
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      side: BorderSide(
                        color: v.id == selectedVehicleId
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    if (vehicles.length > 1)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: GestureDetector(
                          onTap: () => onDeleteVehicle(v),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .shadow
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Theme.of(context).colorScheme.onError,
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
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_filled,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет добавленных автомобилей',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Добавьте автомобиль, чтобы видеть историю ТО и быстро вносить новые записи.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Добавить автомобиль'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
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
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off,
                size: 56,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Пока нет записей ТО',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Нажмите «Добавить ТО», чтобы создать первую запись',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
