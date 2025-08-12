import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'records_list_screen.dart';

class FirestoreSetupScreen extends StatelessWidget {
  const FirestoreSetupScreen({super.key});

  Future<void> _setupTestData(BuildContext context) async {
    try {
      final db = FirebaseFirestore.instance;

      // Очищаем существующие коллекции
      await _clearCollection(db, 'serviceCenters');
      await _clearCollection(db, 'services');
      await _clearCollection(db, 'maintenanceRecords');

      // Добавляем тестовые сервисные центры
      final serviceCenters = [
        {
          'name': 'Автосервис "Мотор"',
          'address': 'ул. Ленина, 10',
          'phone': '+7 (999) 123-45-67',
          'rating': 4.5,
        },
        {
          'name': 'Техцентр "АвтоПрофи"',
          'address': 'пр. Мира, 25',
          'phone': '+7 (999) 765-43-21',
          'rating': 4.8,
        },
        {
          'name': 'Сервис "АвтоМастер"',
          'address': 'ул. Гагарина, 15',
          'phone': '+7 (999) 987-65-43',
          'rating': 4.2,
        },
      ];

      for (final center in serviceCenters) {
        await db.collection('serviceCenters').add(center);
      }

      // Добавляем тестовые услуги
      final services = [
        {
          'name': 'Замена масла',
          'description': 'Замена моторного масла и масляного фильтра',
          'averagePrice': 2000,
        },
        {
          'name': 'Замена тормозных колодок',
          'description': 'Замена передних и задних тормозных колодок',
          'averagePrice': 5000,
        },
        {
          'name': 'Диагностика двигателя',
          'description': 'Компьютерная диагностика двигателя',
          'averagePrice': 1500,
        },
        {
          'name': 'Замена воздушного фильтра',
          'description': 'Замена воздушного фильтра двигателя',
          'averagePrice': 1000,
        },
        {
          'name': 'Замена свечей зажигания',
          'description': 'Замена комплекта свечей зажигания',
          'averagePrice': 3000,
        },
      ];

      for (final service in services) {
        await db.collection('services').add(service);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тестовые данные успешно добавлены')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении тестовых данных: $e')),
        );
      }
    }
  }

  Future<void> _clearCollection(
    FirebaseFirestore db,
    String collectionName,
  ) async {
    final snapshot = await db.collection(collectionName).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка тестовых данных')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Нажмите кнопку ниже, чтобы добавить тестовые данные в Firestore',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _setupTestData(context),
              child: const Text('Добавить тестовые данные'),
            ),
          ],
        ),
      ),
    );
  }
}
