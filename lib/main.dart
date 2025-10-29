import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_client_provider.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/services/supabase_auth_service.dart';
import 'features/splash/presentation/splash_page.dart';
import 'features/admin/presentation/hidden_admin_page.dart';
import 'shared/widgets/main_navigation.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase 초기화 (AppConfig의 하드코딩된 값 사용)
  try {
    await SupabaseClientProvider.init();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase init failed: $e');
    // Supabase 초기화 실패 시에도 앱은 계속 실행되도록 함
  }
  
  runApp(const BookReviewApp());
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // 웹에서 URL 체크
    if (kIsWeb) {
      final uri = Uri.base;
      final path = uri.path;
      final query = uri.queryParameters;
      
      // 관리자 페이지 체크 - URL 파라미터 방식
      if (query.containsKey('admin') && query['admin'] == 'x7k9m2p8q1w5') {
        return const HiddenAdminPage();
      }
      
      // 관리자 페이지 체크 - 경로 방식
      if (path.contains('/admin/config/x7k9m2p8q1w5')) {
        return const HiddenAdminPage();
      }
    }
    
    return const SplashPage();
  }
}

class BookReviewApp extends StatelessWidget {
  const BookReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.theme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Global max-width 360 for mobile-first layout
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const AuthWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await SupabaseAuthService().restoreLoginState();
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainNavigation() : const LoginPage();
  }
}
