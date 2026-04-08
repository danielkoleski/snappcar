import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../providers/invoice_provider.dart';

/// Shows a "Processing…" screen while subscribing to the invoice Realtime
/// channel. When ai_parsed_at becomes non-null, it transitions to show items.
class ProcessingIndicatorPage extends ConsumerWidget {
  const ProcessingIndicatorPage({
    required this.invoiceId,
    required this.vehicleId,
    super.key,
  });

  final String invoiceId;
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceStream = ref.watch(invoiceStreamProvider(invoiceId));

    return invoiceStream.when(
      loading: () => _ProcessingView(),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erro: $e')),
      ),
      data: (invoice) {
        if (invoice.aiParsedAt == null) return _ProcessingView();
        return _ParsedView(invoiceId: invoiceId, vehicleId: vehicleId);
      },
    );
  }
}

class _ProcessingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisando Nota Fiscal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Analisando com IA...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Extraindo itens da nota fiscal',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedView extends ConsumerWidget {
  const _ParsedView({required this.invoiceId, required this.vehicleId});

  final String invoiceId;
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(invoiceItemsProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens Identificados'),
        leading: BackButton(
          onPressed: () => context.go('/vehicles/$vehicleId/invoices'),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Icon(_typeIcon(item.itemType)),
              title: Text(item.description),
              subtitle: Text(_typeLabel(item.itemType)),
              trailing: Text(
                formatBrl(item.unitPrice * item.quantity),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'part' => Icons.settings,
      'labor' => Icons.handyman,
      _ => Icons.receipt,
    };
  }

  String _typeLabel(String type) {
    return switch (type) {
      'part' => 'Peça',
      'labor' => 'Serviço / Mão de obra',
      _ => 'Outro',
    };
  }
}
