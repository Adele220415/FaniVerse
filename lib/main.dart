import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'firebase_options.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/onboarding_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/category_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/events_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/create_content_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'core/appearance_controller.dart';
import 'core/wallpaper_host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase App Check safely
  try {
    if (!kIsWeb) {
      // For mobile platforms - use debug provider in development
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } else if (!kDebugMode) {
      // For web - use ReCaptchaEnterpriseProvider only in release mode
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaEnterpriseProvider('6LfrT9MtAAAAABvMYm_LIIDrpt82J1GRSJBMZdUj'),
      );
    }
  } catch (e) {
    print('App Check activation failed: $e');
  }

  // Loaded before the first frame so the wallpaper does not flash in after a
  // launch with one set. Failures fall back to no wallpaper rather than
  // blocking startup.
  final appearance = await AppearanceController.load();

  runApp(MyApp(appearance: appearance));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appearance});

  final AppearanceController appearance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // The controller is the app's appearance source of truth, so rebuilding
      // on its notifications is what applies a wallpaper change app-wide.
      animation: appearance,
      builder: (context, _) {
        final wallpaper = appearance.wallpaper;

        // The extension is what lets screens read the wallpaper's influence
        // through Theme.of, so it is rebuilt into the theme on every change.
        final theme = AppTheme.dark.copyWith(
          extensions: [WallpaperTheme(anchors: appearance.anchors)],
        );

        // Above MaterialApp, not inside its home.
        //
        // An InheritedWidget is only visible to its descendants, and every
        // pushed route is a *sibling* of `home` in the navigator rather than a
        // descendant of it. Scoping to `home` therefore left every dialog, sheet
        // and pushed page unable to read the controller - which is how the
        // settings sheet, and the wallpaper screen opened from it, both saw no
        // controller at all. Wrapping the app itself is the only placement
        // that covers the navigator's whole stack.
        return AppearanceScope(
          controller: appearance,
          child: MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            // One theme for the whole app. Screens previously each rebuilt their
            // own TextTheme, which is why spacing and type had drifted between
            // tabs.
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.dark,
            // The wallpaper is painted inside the navigator so it sits behind
            // every route, including ones pushed later.
            builder: (context, child) => WallpaperHost(
              appearance: appearance,
              wallpaper: wallpaper,
              child: child ?? const SizedBox.shrink(),
            ),
            // Initial route based on auth state
            home: const AuthWrapper(),
            // Named routes
            routes: {
              '/login': (context) => const LoginScreenWrapper(),
              '/register': (context) => const RegisterScreenWrapper(),
              '/categories': (context) => const CategorySelectionWrapper(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/main': (context) => const MainNavigationWrapper(),
            },
          ),
        );
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

  /// Set once onboarding has been completed or skipped this session.
  ///
  /// Onboarding is rendered as the *root* of this subtree, not pushed as a
  /// route, so there is nothing for it to pop: `Navigator.maybePop` on the home
  /// route is a no-op and the fan would be stranded on page one forever. The
  /// subtree has to be swapped in state instead.
  bool _onboardingSettled = false;

  /// In-flight decision per uid, so the storage read happens once per sign-in
  /// rather than on every rebuild of this widget.
  ///
  /// The value is stored rather than the boolean it resolves to, because
  /// rebuilding must not re-run the read: it would race the write that
  /// finishing the tour just made, and the subtree could flip back to
  /// onboarding after the fan had walked away from it.
  final Map<String, Future<bool>> _onboardingChecks = {};

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
                // Onboarding is device-local state read once per sign-in. A
                // reader who finished it goes straight to the app; one who
                // skipped is asked again after Preferences.resurfaceAfter.
                if (_onboardingSettled) {
                  return const MainNavigationWrapper();
                }

                return FutureBuilder<bool>(
                  future: _shouldOnboard(user.uid),
                  builder: (context, onboardingSnapshot) {
                    if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (onboardingSnapshot.data ?? false) {
                      return OnboardingScreen(
                        onFinished: (_) => setState(() => _onboardingSettled = true),
                      );
                    }
                    return const MainNavigationWrapper();
                  },
                );
              } else {
                return const CategorySelectionWrapper();
              }
            },
          );
        } else {
          // Signing out drops the in-memory onboarding state, so the next
          // sign-in on this device re-reads the stored record. The record itself
          // survives: a reader who finished the tour does not get it again just
          // for switching accounts.
          _onboardingSettled = false;
          _onboardingChecks.clear();
          return const LoginScreenWrapper();
        }
      },
    );
  }

  /// True when the tour should be shown to this device right now.
  ///
  /// Delegates the "is it due?" judgement to [Preferences], which owns the
  /// 72-hour rule, and memoises the *future* per uid rather than its result.
  /// Holding the future is what makes a rebuild reuse the same read instead of
  /// starting another one that could resolve differently.
  Future<bool> _shouldOnboard(String userId) {
    return _onboardingChecks.putIfAbsent(userId, () async {
      try {
        return await prefsShouldShowOnboarding();
      } catch (e) {
        // Failing open here would show the tour to everyone on a storage error;
        // failing closed strands someone who has genuinely not seen it.
        debugPrint('onboarding check failed: $e');
        return true;
      }
    });
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
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  void _onNavTap(int index) {
    if (index == 0 && _currentIndex == 0) {
      // Re-tap on home → refresh content
      _homeKey.currentState?.refresh();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// After a post is published, return to the home tab so the author can see
  /// it in the feed. Switching tabs is the only correct way to leave the create
  /// screen, since it has no route of its own.
  void _goHomeAfterPublish() {
    if (_currentIndex == 0) {
      // Already home: refresh so the new post shows up immediately.
      _homeKey.currentState?.refresh();
      return;
    }
    setState(() => _currentIndex = 0);
    _homeKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey, authService: _authService),
          const ExploreScreen(),
          // Publishing hands control back to the shell. This screen is a tab in
          // an IndexedStack, so it must never call Navigator.pop - there is no
          // route underneath it, and popping would empty the navigator and
          // leave a blank white page.
          CreateContentScreen(onPublished: _goHomeAfterPublish),
          const EventsScreen(),
          const ShopScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}