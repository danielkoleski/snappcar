import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../providers/maintenance_provider.dart';
import '../widgets/maintenance_card.dart';

class MaintenanceListPage extends ConsumerWidget {
  const MaintenanceListPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(maintenanceListProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Manutenções')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/vehicles/$vehicleId/maintenance/add'),
        icon: const Icon(Icons.add),
        label: const Text('Nova manutenção'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text('Nenhum registro de manutenção'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(maintenanceListProvider(vehicleId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  MaintenanceCard(record: records[index]),
            ),
          );
        },
      ),
    );
  }
}
