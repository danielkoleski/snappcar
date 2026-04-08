import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/mileage_entry_model.dart';
import '../../providers/mileage_provider.dart';

class MileagePage extends ConsumerWidget {
  const MileagePage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(mileageListProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quilometragem')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar km'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (entries) => entries.isEmpty
            ? const Center(
                child: Text('Nenhum registro de quilometragem'),
              )
            : _MileageContent(entries: entries),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final kmController = TextEditingController();
    final notesController = TextEditingController();
    DateTime recordedAt = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registrar Quilometragem',
                style: ctx.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: kmController,
                decoration: const InputDecoration(
                  labelText: 'Quilometragem atual *',
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(formatDate(recordedAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: recordedAt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setModalState(() => recordedAt = date);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration:
                    const InputDecoration(labelText: 'Observações'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final km = int.tryParse(kmController.text.trim());
                  if (km == null || km <= 0) return;
                  final entry = MileageEntry(
                    id: '',
                    vehicleId: vehicleId,
                    recordedKm: km,
                    recordedAt: recordedAt,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await ref
                      .read(mileageNotifierProvider.notifier)
                      .create(entry);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MileageContent extends StatelessWidget {
  const _MileageContent({required this.entries});

  final List<MileageEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Chart
        if (entries.length >= 2) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico de quilometragem',
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _MileageChart(entries: entries),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // List of entries
        ...entries.reversed.map(
          (e) => ListTile(
            leading: const Icon(Icons.speed),
            title: Text('${e.recordedKm} km'),
            subtitle: Text(formatDate(e.recordedAt)),
            trailing: e.notes != null
                ? Tooltip(
                    message: e.notes!,
                    child: const Icon(Icons.info_outline, size: 16),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _MileageChart extends StatelessWidget {
  const _MileageChart({required this.entries});

  final List<MileageEntry> entries;

  @override
  Widget build(BuildContext context) {
    final spots = entries
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            e.value.recordedKm.toDouble(),
          ),
        )
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: context.colors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: context.colors.primary.withOpacity(0.1),
            ),
          ),
        ],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000).toStringAsFixed(0)}k',
                style: context.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }
}
