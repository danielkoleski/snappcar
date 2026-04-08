import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../data/models/maintenance_record_model.dart';
import '../../providers/maintenance_provider.dart';

class AddMaintenancePage extends ConsumerStatefulWidget {
  const AddMaintenancePage({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  ConsumerState<AddMaintenancePage> createState() =>
      _AddMaintenancePageState();
}

class _AddMaintenancePageState extends ConsumerState<AddMaintenancePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workshopController = TextEditingController();
  final _costController = TextEditingController();
  final _nextDueKmController = TextEditingController();
  DateTime _performedAt = DateTime.now();
  DateTime? _nextDueAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _workshopController.dispose();
    _costController.dispose();
    _nextDueKmController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isPerformed}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isPerformed ? _performedAt : (_nextDueAt ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (isPerformed) {
        _performedAt = date;
      } else {
        _nextDueAt = date;
      }
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      context.showSnackBar('Título é obrigatório', isError: true);
      return;
    }

    final costText = _costController.text.trim().replaceAll(',', '.');
    final cost = costText.isEmpty ? null : double.tryParse(costText);
    final nextKm = _nextDueKmController.text.trim().isEmpty
        ? null
        : int.tryParse(_nextDueKmController.text.trim());

    final record = MaintenanceRecord(
      id: '',
      vehicleId: widget.vehicleId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      performedAt: _performedAt,
      nextDueAt: _nextDueAt,
      nextDueKm: nextKm,
      costBrl: cost,
      workshopName: _workshopController.text.trim().isEmpty
          ? null
          : _workshopController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(maintenanceNotifierProvider.notifier).create(record);

    if (!mounted) return;
    final state = ref.read(maintenanceNotifierProvider);
    state.whenOrNull(
      data: (_) => context.pop(),
      error: (e, _) => context.showSnackBar(e.toString(), isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(maintenanceNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Manutenção')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex: Troca de óleo',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data de realização *'),
                subtitle: Text(
                  '${_performedAt.day.toString().padLeft(2, '0')}/'
                  '${_performedAt.month.toString().padLeft(2, '0')}/'
                  '${_performedAt.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isPerformed: true),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Próxima revisão (data)'),
                subtitle: Text(
                  _nextDueAt == null
                      ? 'Não definida'
                      : '${_nextDueAt!.day.toString().padLeft(2, '0')}/'
                          '${_nextDueAt!.month.toString().padLeft(2, '0')}/'
                          '${_nextDueAt!.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isPerformed: false),
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nextDueKmController,
                decoration: const InputDecoration(
                  labelText: 'Próxima revisão (km)',
                  hintText: 'Ex: 50000',
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Custo',
                  prefixText: r'R$ ',
                  hintText: '0,00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _workshopController,
                decoration: const InputDecoration(
                  labelText: 'Oficina',
                  hintText: 'Nome da oficina',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
