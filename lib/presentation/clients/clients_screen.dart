import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouveau client',
            onPressed: () => _tryAddClient(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(),
          const Expanded(child: _ClientList()),
        ],
      ),
    );
  }

  void _tryAddClient(BuildContext context) {
    // Vérifie la limite avant de naviguer
    final sub = context.read<SubscriptionProvider>();
    final clientProvider = context.read<ClientProvider>();

    // On lit le stream une fois pour avoir le compte actuel
    clientProvider.watchClients().first.then((clients) {
      if (!context.mounted) return;
      if (!sub.canAddClient(clients.length)) {
        _showLimitDialog(context);
      } else {
        context.push('/clients/add');
      }
    });
  }

  void _showLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limite atteinte'),
        content: const Text(
          'Vous avez atteint la limite de 30 clients pour l\'offre gratuite.\n\n'
          'Passez au Pro pour des clients illimités.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              ctx.pop();
              context.push('/upgrade', extra: 'clients');
            },
            child: const Text('Passer au Pro'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un client...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (v) => context.read<ClientProvider>().setSearchQuery(v),
      ),
    );
  }
}

class _ClientList extends StatelessWidget {
  const _ClientList();

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return StreamBuilder<List<ClientModel>>(
      stream: context.read<ClientProvider>().watchClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }

        final all = snapshot.data ?? [];
        final query = context.watch<ClientProvider>().searchQuery;
        final clients = query.isEmpty
            ? all
            : all.where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.phone.contains(query)).toList();

        return Column(
          children: [
            // Bandeau de limite gratuite
            if (!sub.isPro && all.length >= SubscriptionProvider.maxFreeClients)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Limite de 30 clients atteinte — passez au Pro',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/upgrade', extra: 'clients'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Pro', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            if (clients.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        query.isEmpty
                            ? 'Aucun client pour l\'instant'
                            : 'Aucun résultat pour "$query"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (query.isEmpty) ...[
                        const SizedBox(height: AppSizes.paddingMedium),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/clients/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un client'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                  itemCount: clients.length,
                  itemBuilder: (context, index) => _ClientTile(client: clients[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientModel client;
  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(client.phone),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/clients/${client.id}'),
      ),
    );
  }
}
