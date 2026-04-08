import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/extensions/build_context_extensions.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirstAccess = _isFirstAccess();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
        automaticallyImplyLeading: !isFirstAccess,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Política de Privacidade — SnappCar',
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Última atualização: janeiro de 2025',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: '1. Dados coletados',
                    content:
                        'O SnappCar coleta as seguintes informações:\n\n'
                        '• Nome completo e e-mail (conta)\n'
                        '• Marca, modelo, ano e placa do veículo\n'
                        '• Leituras de odômetro\n'
                        '• Fotos de notas fiscais\n'
                        '• Registros de manutenção\n'
                        '• Token do dispositivo (para notificações)',
                  ),
                  _Section(
                    title: '2. Finalidade do tratamento',
                    content:
                        'Os dados são utilizados exclusivamente para:\n\n'
                        '• Gerenciar o histórico de manutenção do seu veículo\n'
                        '• Enviar lembretes de manutenção\n'
                        '• Extrair informações de notas fiscais via IA\n'
                        '• Melhorar a experiência do aplicativo',
                  ),
                  _Section(
                    title: '3. Armazenamento',
                    content:
                        'Os dados são armazenados na plataforma Supabase, '
                        'região São Paulo (sa-east-1), dentro do território '
                        'brasileiro, em conformidade com a LGPD.',
                  ),
                  _Section(
                    title: '4. Compartilhamento',
                    content:
                        'Não compartilhamos seus dados pessoais com terceiros, '
                        'exceto quando necessário para operação do serviço '
                        '(processamento de imagens por IA). Nenhum dado é '
                        'vendido ou utilizado para publicidade.',
                  ),
                  _Section(
                    title: '5. Seus direitos (LGPD)',
                    content:
                        'Você tem direito a:\n\n'
                        '• Confirmar a existência do tratamento\n'
                        '• Acessar seus dados\n'
                        '• Corrigir dados incompletos\n'
                        '• Solicitar a exclusão (disponível em Perfil → Excluir conta)\n'
                        '• Revogar o consentimento a qualquer momento',
                  ),
                  _Section(
                    title: '6. Exclusão de dados',
                    content:
                        'Ao excluir sua conta:\n\n'
                        '• Seus dados pessoais (nome, e-mail, placa, fotos) '
                        'são removidos permanentemente.\n'
                        '• Dados de veículos são anonimizados (placa removida, '
                        'proprietário desvinculado).\n'
                        '• Histórico de manutenção é anonimizado (oficina e custo removidos).',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (isFirstAccess)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _acceptPolicy(context),
                  child: const Text('Aceitar e continuar'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isFirstAccess() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    // Check via user metadata or profile query; simplified here
    return false;
  }

  Future<void> _acceptPolicy(BuildContext context) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      await Supabase.instance.client.from('profiles').update({
        'privacy_accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);

      if (context.mounted) context.go('/vehicles');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
