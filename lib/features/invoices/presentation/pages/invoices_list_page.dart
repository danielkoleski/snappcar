import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../providers/invoice_provider.dart';

class InvoicesListPage extends ConsumerWidget {
  const InvoicesListPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Notas Fiscais')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/vehicles/$vehicleId/invoices/capture'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Fotografar nota'),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (invoices) {
          if (invoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma nota fiscal registrada'),
                  SizedBox(height: 8),
                  Text(
                    'Tire foto de uma nota para registrar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(invoicesListProvider(vehicleId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final inv = invoices[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(
                      inv.issuedAt != null
                          ? formatDate(inv.issuedAt)
                          : 'Nota fiscal',
                    ),
                    subtitle: inv.totalBrl != null
                        ? Text(formatBrl(inv.totalBrl))
                        : null,
                    trailing: inv.aiParsedAt == null
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
