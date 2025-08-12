import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project1/screens/add_record_screen.dart';

class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('maintenanceRecords')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data?.docs ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;
            final date = DateTime.parse(record['date'] as String);

            return Card(
              child: InkWell(
                onTap: () => _showRecordDetails(context, record),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd.MM.yyyy').format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Пробег: ${record['mileage']} км'),
                      Text('Стоимость: ${record['cost']} ₽'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Детали записи ТО',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('serviceCenters')
                                  .doc(record['serviceCenterID'])
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final centerData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Сервисный центр: ${centerData['name']}',
                                  ),
                                  Text('Адрес: ${centerData['address']}'),
                                ],
                              );
                            }
                            return const Text(
                              'Загрузка данных сервисного центра...',
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Выполненные услуги:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('services')
                                  .where(
                                    FieldPath.documentId,
                                    whereIn: record['servicesPerformed'],
                                  )
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Column(
                                children:
                                    snapshot.data!.docs.map((doc) {
                                      final service =
                                          doc.data() as Map<String, dynamic>;
                                      return ListTile(
                                        title: Text(service['name']),
                                        subtitle: Text(
                                          '${service['averagePrice']} ₽',
                                        ),
                                      );
                                    }).toList(),
                              );
                            }
                            return const Text('Загрузка услуг...');
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(record['date']))}',
                        ),
                        Text('Пробег: ${record['mileage']} км'),
                        Text('Общая стоимость: ${record['cost']} ₽'),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}
