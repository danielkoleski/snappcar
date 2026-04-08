import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../auth/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(
                    (user?.userMetadata?['full_name'] as String? ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.userMetadata?['full_name'] as String? ?? '',
                  style: context.textTheme.titleLarge,
                ),
                Text(
                  user?.email ?? '',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Settings
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair da conta'),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          const Divider(),

          // Danger zone
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zona de perigo',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.error,
                    side: BorderSide(color: context.colors.error),
                  ),
                  onPressed: () => _confirmDeleteAccount(context, ref),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Excluir minha conta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final textController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seus dados pessoais serão removidos permanentemente. '
              'Esta ação não pode ser desfeita.',
            ),
            const SizedBox(height: 16),
            const Text('Digite EXCLUIR para confirmar:'),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'EXCLUIR',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              if (textController.text.trim() == 'EXCLUIR') {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await Supabase.instance.client.rpc('delete_account');
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          'Erro ao excluir conta: $e',
          isError: true,
        );
      }
    }
  }
}
