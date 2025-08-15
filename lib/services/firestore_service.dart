import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? "";

  // Vehicles
  Stream<List<Vehicle>> getUserVehicles() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Vehicle.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<String> addVehicle(Vehicle vehicle) async {
    final ref =
        await _db.collection('users').doc(userId).collection('vehicles').add({
      ...vehicle.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Maintenance records scoped to vehicle
  Stream<List<MaintenanceRecord>> getVehicleMaintenance(String vehicleId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .collection('maintenanceRecords')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRecord.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<void> addMaintenanceRecord(
    String vehicleId,
    MaintenanceRecord record,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .collection('maintenanceRecords')
        .add({
      ...record.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMaintenanceRecord(
    String vehicleId,
    String recordId,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .collection('maintenanceRecords')
        .doc(recordId)
        .delete();
  }

  Future<void> deleteVehicle(String vehicleId) async {
    // Delete all maintenance records first
    final records = await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .collection('maintenanceRecords')
        .get();

    final batch = _db.batch();
    for (final doc in records.docs) {
      batch.delete(doc.reference);
    }
    // Delete vehicle document
    batch.delete(_db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId));

    await batch.commit();
  }
}
