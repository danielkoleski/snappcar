import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: ListView(
        children: [
          enabledAsync.when(
            loading: () => const ListTile(
              title: Text('Carregando...'),
              trailing: CircularProgressIndicator(),
            ),
            error: (e, _) => ListTile(title: Text(e.toString())),
            data: (enabled) => SwitchListTile(
              title: const Text('Lembretes de manutenção'),
              subtitle: const Text(
                'Receba alertas quando manutenções estiverem vencendo',
              ),
              value: enabled,
              onChanged: (value) async {
                // In a real implementation, pass the FCM token here
                await ref
                    .read(notificationSettingsNotifierProvider.notifier)
                    .setEnabled('current_token', enabled: value);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre as notificações'),
            subtitle: const Text(
              'As notificações são enviadas com base nas datas e quilometragens '
              'de próxima revisão registradas.',
            ),
          ),
        ],
      ),
    );
  }
}
