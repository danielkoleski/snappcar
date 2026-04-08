import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../maintenance/providers/maintenance_provider.dart';
import '../../providers/vehicles_provider.dart';

class VehicleDetailPage extends ConsumerWidget {
  const VehicleDetailPage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(vehicleId));
    final healthAsync = ref.watch(healthScoreProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: vehicleAsync.maybeWhen(
          data: (v) => Text('${v.make} ${v.model}'),
          orElse: () => const Text('Veículo'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (vehicle) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Health score card
            healthAsync.maybeWhen(
              data: (score) => _HealthCard(score: score),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Vehicle info
            _InfoCard(
              children: [
                _InfoRow('Marca', vehicle.make),
                _InfoRow('Modelo', vehicle.model),
                _InfoRow('Ano', vehicle.year.toString()),
                _InfoRow('Cor', vehicle.color),
                if (vehicle.plate != null) _InfoRow('Placa', vehicle.plate!),
                _InfoRow(
                  'Quilometragem',
                  '${vehicle.odometer} km',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            _QuickActionButton(
              icon: Icons.build_outlined,
              label: 'Manutenções',
              onTap: () =>
                  context.push('/vehicles/$vehicleId/maintenance'),
            ),
            const SizedBox(height: 12),
            _QuickActionButton(
              icon: Icons.speed_outlined,
              label: 'Quilometragem',
              onTap: () =>
                  context.push('/vehicles/$vehicleId/mileage'),
            ),
            const SizedBox(height: 12),
            _QuickActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'Notas Fiscais',
              onTap: () =>
                  context.push('/vehicles/$vehicleId/invoices'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: const Text(
          'Esta ação não pode ser desfeita. Todo o histórico será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(vehiclesNotifierProvider.notifier).delete(vehicleId);
    if (context.mounted) context.go('/vehicles');
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.score});

  final int score;

  Color get _color {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: score / 100,
              color: _color,
              backgroundColor: Colors.grey.withOpacity(0.2),
              strokeWidth: 8,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saúde do Veículo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$score%',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: _color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
