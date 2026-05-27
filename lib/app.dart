import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_sizes.dart';
import 'data/models/client_model.dart';
import 'data/models/invoice_model.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/clients/clients_screen.dart';
import 'presentation/clients/add_edit_client_screen.dart';
import 'presentation/clients/client_detail_screen.dart';
import 'presentation/invoices/invoices_screen.dart';
import 'presentation/invoices/add_edit_invoice_screen.dart';
import 'presentation/invoices/invoice_detail_screen.dart';
import 'presentation/payments/payments_screen.dart';
import 'providers/client_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/payment_provider.dart';

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isOnAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isOnAuth) return '/login';
    if (isLoggedIn && isOnAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    // Clients
    GoRoute(path: '/clients', builder: (_, __) => const ClientsScreen()),
    GoRoute(path: '/clients/add', builder: (_, __) => const AddEditClientScreen()),
    GoRoute(
      path: '/clients/:id',
      builder: (_, state) =>
          ClientDetailScreen(clientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/clients/:id/edit',
      builder: (_, state) =>
          AddEditClientScreen(client: state.extra as ClientModel?),
    ),
    // Paiements
    GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
    // Factures
    GoRoute(path: '/invoices', builder: (_, __) => const InvoicesScreen()),
    GoRoute(
      path: '/invoices/add',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddEditInvoiceScreen(
          prefillClientId: extra?['clientId'] as String?,
          prefillClientName: extra?['clientName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/invoices/:id',
      builder: (_, state) =>
          InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/invoices/:id/edit',
      builder: (_, state) =>
          AddEditInvoiceScreen(invoice: state.extra as InvoiceModel?),
    ),
  ],
);

class PayRappelApp extends StatelessWidget {
  const PayRappelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp.router(
        title: 'PayRappel',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.backgroundLight,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall + 6,
            ),
          ),
        ),
      ),
    );
  }
}
