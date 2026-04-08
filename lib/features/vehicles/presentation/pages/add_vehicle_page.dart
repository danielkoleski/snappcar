import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../data/models/vehicle_model.dart';
import '../../providers/fipe_provider.dart';
import '../../providers/vehicles_provider.dart';

class AddVehiclePage extends ConsumerStatefulWidget {
  const AddVehiclePage({super.key});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  FipeMake? _selectedMake;
  FipeModel? _selectedModel;
  FipeYear? _selectedYear;
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();

  @override
  void dispose() {
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedMake == null ||
        _selectedModel == null ||
        _selectedYear == null ||
        _colorController.text.trim().isEmpty) {
      context.showSnackBar('Preencha todos os campos obrigatórios', isError: true);
      return;
    }

    final yearInt = int.tryParse(_selectedYear!.code.split('-').first) ?? 0;
    final uid = Supabase.instance.client.auth.currentUser!.id;

    final vehicle = Vehicle(
      id: '',
      ownerId: uid,
      make: _selectedMake!.name,
      model: _selectedModel!.name,
      year: yearInt,
      color: _colorController.text.trim(),
      plate: _plateController.text.trim().isEmpty
          ? null
          : _plateController.text.trim().toUpperCase(),
      fipeCode: _selectedModel!.code,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(vehiclesNotifierProvider.notifier).create(vehicle);

    if (!mounted) return;
    final state = ref.read(vehiclesNotifierProvider);
    state.whenOrNull(
      data: (_) => context.pop(),
      error: (e, _) =>
          context.showSnackBar(e.toString(), isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(vehiclesNotifierProvider).isLoading;
    final makesAsync = ref.watch(fipeMakesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Veículo'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Marca
              makesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erro ao carregar marcas: $e'),
                data: (makes) => DropdownButtonFormField<FipeMake>(
                  decoration: const InputDecoration(labelText: 'Marca *'),
                  value: _selectedMake,
                  items: makes
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedMake = value;
                    _selectedModel = null;
                    _selectedYear = null;
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Modelo
              if (_selectedMake != null)
                Consumer(
                  builder: (context, ref, _) {
                    final modelsAsync =
                        ref.watch(fipeModelsProvider(_selectedMake!.code));
                    return modelsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erro ao carregar modelos: $e'),
                      data: (models) => DropdownButtonFormField<FipeModel>(
                        decoration: const InputDecoration(labelText: 'Modelo *'),
                        value: _selectedModel,
                        items: models
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _selectedModel = value;
                          _selectedYear = null;
                        }),
                      ),
                    );
                  },
                ),
              if (_selectedMake != null) const SizedBox(height: 16),

              // Ano
              if (_selectedModel != null)
                Consumer(
                  builder: (context, ref, _) {
                    final yearsAsync = ref.watch(
                      fipeYearsProvider(
                        _selectedMake!.code,
                        _selectedModel!.code,
                      ),
                    );
                    return yearsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erro ao carregar anos: $e'),
                      data: (years) => DropdownButtonFormField<FipeYear>(
                        decoration: const InputDecoration(labelText: 'Ano *'),
                        value: _selectedYear,
                        items: years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedYear = value),
                      ),
                    );
                  },
                ),
              if (_selectedModel != null) const SizedBox(height: 16),

              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Cor *',
                  hintText: 'Ex: Prata',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Placa',
                  hintText: 'ABC-1234',
                ),
                textCapitalization: TextCapitalization.characters,
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
                    : const Text('Salvar veículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
