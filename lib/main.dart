import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/category_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/events_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/create_content_screen.dart';
import 'widgets/bottom_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      // Initial route based on auth state
      home: const AuthWrapper(),
      // Named routes
      routes: {
        '/login': (context) => const LoginScreenWrapper(),
        '/register': (context) => const RegisterScreenWrapper(),
        '/categories': (context) => const CategorySelectionWrapper(),
        '/main': (context) => const MainNavigationWrapper(),
      },
    );
  }
}

// Auth wrapper to handle authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        
        if (user != null) {
          // User is logged in, check if they have selected categories
          return FutureBuilder<bool>(
            future: _checkUserCategories(user.uid),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              final hasCategories = categorySnapshot.data ?? false;
              
              if (hasCategories) {
                return const MainNavigationWrapper();
              } else {
                return const CategorySelectionWrapper();
              }
            },
          );
        } else {
          return const LoginScreenWrapper();
        }
      },
    );
  }

  Future<bool> _checkUserCategories(String userId) async {
    try {
      final result = await _authService.hasUserSelectedCategories();
      return result.isSuccess ? result.data ?? false : false;
    } catch (e) {
      return false;
    }
  }
}

// Wrapper for Login Screen with navigation callbacks
class LoginScreenWrapper extends StatelessWidget {
  const LoginScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onLoginSuccess: () {
        // Let the AuthWrapper StreamBuilder handle the navigation
        // Just pop to let the auth state change trigger navigation
        Navigator.of(context).pop();
      },
      onGoToRegister: () {
        Navigator.of(context).pushNamed('/register');
      },
    );
  }
}

// Wrapper for Register Screen with navigation callbacks
class RegisterScreenWrapper extends StatelessWidget {
  const RegisterScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterScreen(
      onRegisterSuccess: () {
        Navigator.of(context).pushReplacementNamed('/categories');
      },
      onGoToLogin: () {
        Navigator.of(context).pop();
      },
    );
  }
}

// Wrapper for Category Selection Screen with navigation callbacks
class CategorySelectionWrapper extends StatelessWidget {
  const CategorySelectionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return CategorySelectionScreen(
      onSelectionComplete: () {
        Navigator.of(context).pushReplacementNamed('/main');
      },
    );
  }
}

// Main Navigation Wrapper
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(authService: _authService),
          const ExploreScreen(),
          const CreateContentScreen(),
          const EventsScreen(),
          const ShopScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}