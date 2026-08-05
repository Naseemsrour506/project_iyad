import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'providers/alerts_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/messages_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/alerts_service.dart';
import 'services/analysis_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/children_service.dart';
import 'services/dashboard_service.dart';
import 'services/messages_service.dart';
import 'services/token_storage_service.dart';
import 'widgets/main_navigation.dart';

/// Root widget: builds the service graph, exposes the providers and forces the
/// whole app into Hebrew right-to-left.
class SafeKidApp extends StatefulWidget {
  const SafeKidApp({super.key, this.tokenStorage, this.apiService});

  /// Injection points used by tests; production uses the defaults.
  final TokenStorageService? tokenStorage;
  final ApiService? apiService;

  @override
  State<SafeKidApp> createState() => _SafeKidAppState();
}

class _SafeKidAppState extends State<SafeKidApp> {
  late final TokenStorageService _tokenStorage;
  late final ApiService _apiService;
  late final AuthProvider _authProvider;
  late final ChildrenProvider _childrenProvider;
  late final DashboardProvider _dashboardProvider;
  late final MessagesProvider _messagesProvider;
  late final AlertsProvider _alertsProvider;

  @override
  void initState() {
    super.initState();

    _tokenStorage = widget.tokenStorage ?? SecureTokenStorageService();
    _apiService = widget.apiService ?? ApiService(tokenStorage: _tokenStorage);

    _authProvider = AuthProvider(
      authService: AuthService(api: _apiService, storage: _tokenStorage),
    );
    _childrenProvider = ChildrenProvider(
      childrenService: ChildrenService(api: _apiService),
    );
    _dashboardProvider = DashboardProvider(
      dashboardService: DashboardService(api: _apiService),
    );
    _messagesProvider = MessagesProvider(
      messagesService: MessagesService(api: _apiService),
      analysisService: AnalysisService(api: _apiService),
    );
    _alertsProvider = AlertsProvider(
      alertsService: AlertsService(api: _apiService),
    );

    // A rejected token anywhere in the app tears the session down centrally.
    _apiService.onUnauthorized = _handleUnauthorized;

    _authProvider.addListener(_clearDataOnLogout);
    _authProvider.initialize();
  }

  void _handleUnauthorized() {
    _authProvider.handleUnauthorized();
  }

  /// Feature state must not leak between accounts on the same device.
  void _clearDataOnLogout() {
    if (_authProvider.isAuthenticated) return;

    _childrenProvider.reset();
    _dashboardProvider.reset();
    _messagesProvider.reset();
    _alertsProvider.reset();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_clearDataOnLogout);
    _apiService.onUnauthorized = null;
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ChildrenProvider>.value(
          value: _childrenProvider,
        ),
        ChangeNotifierProvider<DashboardProvider>.value(
          value: _dashboardProvider,
        ),
        ChangeNotifierProvider<MessagesProvider>.value(
          value: _messagesProvider,
        ),
        ChangeNotifierProvider<AlertsProvider>.value(value: _alertsProvider),
      ],
      child: MaterialApp(
        title: 'Safe Kid App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // The entire UI is Hebrew, so the layout direction is fixed to RTL.
        builder: (BuildContext context, Widget? child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: AppRoutes.splash,
        routes: <String, WidgetBuilder>{
          AppRoutes.splash: (_) => const AuthGate(),
          AppRoutes.register: (_) => const RegisterScreen(),
        },
      ),
    );
  }
}

/// Chooses between splash, login and the authenticated shell based on
/// [AuthProvider.status].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthStatus status = context.select<AuthProvider, AuthStatus>(
      (AuthProvider provider) => provider.status,
    );

    switch (status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const MainNavigation();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
