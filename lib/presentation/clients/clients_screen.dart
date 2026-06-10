import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.transparent,
  centerTitle: false,
  title: const Text(
    "Clients",
    style: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  ),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A73E8),
              Color(0xFF34A853),
            ],
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.add,color: Colors.white),
          onPressed: () => context.push('/clients/add'),
        ),
      ),
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
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
  margin: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: TextField(
    decoration: InputDecoration(
      hintText: "Rechercher un client",
      prefixIcon: const Icon(
        Icons.search,
        color: AppColors.primary,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    ),
    onChanged: (v) =>
        context.read<ClientProvider>().setSearchQuery(v),
  ),
);
  }
}

class _ClientList extends StatelessWidget {
  const _ClientList();

  @override
  Widget build(BuildContext context) {
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
            : all
                .where((c) =>
                    c.name.toLowerCase().contains(query.toLowerCase()) ||
                    c.phone.contains(query))
                .toList();

        if (clients.isEmpty) {
          return Center(
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
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium),
          itemCount: clients.length,
          itemBuilder: (context, index) =>
              _ClientTile(client: clients[index]),
        );
      },
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientModel client;

  const _ClientTile({
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () =>
              context.push('/clients/${client.id}'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1A73E8),
                        Color(0xFF34A853),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        client.phone,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
