import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/main_dashboard.dart';
import 'screens/groups/groups_screen.dart';
import 'screens/groups/group_detail_screen.dart';
import 'screens/contacts/contacts_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/user/user_screen.dart';

void main() {
  runApp(const SimpleSplitApp());
}

class SimpleSplitApp extends StatelessWidget {
  const SimpleSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'The Simple Split',
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final location = state.uri.toString();
        print('[GoRouter] ===== REDIRECT CHECK =====');
        print('[GoRouter] Current location: $location');
        print('[GoRouter] isLoading: ${authProvider.isLoading}');
        print('[GoRouter] isAuthenticated: ${authProvider.isAuthenticated}');
        print('[GoRouter] user: ${authProvider.user?.name ?? 'null'}');
        
        // Se ainda está carregando, mostrar splash
        if (authProvider.isLoading) {
          print('[GoRouter] ➡️ Redirecionando para /splash (carregando)');
          return '/splash';
        }

        // Se não está autenticado (incluindo na splash após loading), redirecionar para login
        if (!authProvider.isAuthenticated) {
          if (location.startsWith('/auth')) {
            // Já está na área de autenticação, permitir
            print('[GoRouter] ✅ Navegação permitida para área de auth: $location');
            return null;
          } else {
            // Qualquer outra página quando não autenticado -> login
            print('[GoRouter] ➡️ Não autenticado, redirecionando para /auth/login');
            return '/auth/login';
          }
        }

        // Se está autenticado e está na splash ou auth, redirecionar para dashboard
        if (authProvider.isAuthenticated && 
            (location == '/splash' || location.startsWith('/auth'))) {
          print('[GoRouter] ➡️ Autenticado, redirecionando para /dashboard');
          return '/dashboard';
        }

        // Permitir navegação normal
        print('[GoRouter] ✅ Navegação permitida para: $location');
        print('[GoRouter] ==============================');
        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        // 2FA removido para login direto - vai direto ao dashboard

        // Main Dashboard
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const MainDashboard(),
        ),

        // Groups
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupsScreen(),
        ),
        GoRoute(
          path: '/groups/:groupId',
          builder: (context, state) {
            final String? groupId = state.pathParameters['groupId'];
            
            print('[GoRouter] ===== DEBUG GRUPO =====');
            print('[GoRouter] GroupId recebido: $groupId');
            print('[GoRouter] Tipo: ${groupId.runtimeType}');
            print('[GoRouter] É nulo? ${groupId == null}');
            print('[GoRouter] Está vazio? ${groupId?.isEmpty}');
            print('[GoRouter] =============================');
            
            if (groupId == null || groupId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Grupo não encontrado')),
              );
            }
            
            // Retornar tela real do grupo
            return GroupDetailScreen(groupId: groupId);
            
            // return GroupDetailScreen(groupId: groupId);
          },
        ),

        // Contacts
        GoRoute(
          path: '/contacts',
          builder: (context, state) => const ContactsScreen(),
        ),

        // Insights
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsScreen(),
        ),

        // Marketplace
        GoRoute(
          path: '/marketplace',
          builder: (context, state) => const MarketplaceScreen(),
        ),

        // User Profile
        GoRoute(
          path: '/user',
          builder: (context, state) => const UserScreen(),
        ),
      ],
    );
  }
}