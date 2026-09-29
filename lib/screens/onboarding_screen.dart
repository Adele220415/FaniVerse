import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../services/onboarding_preferences.dart';

/// The first-run tour: three pages of copy over an illustration.
///
/// ## Why the copy lives inside the PageView
///
/// An earlier version rendered the *current* page's text and art from an
/// `_index` field, while still calling `_controller.nextPage()` on a
/// `PageController` that was never attached to anything. That throws
/// "PageController.page cannot be accessed before a PageView is built with it"
/// the moment Next is tapped - so the button was dead. Everything the page
/// shows is now built by the `PageView` itself, and `_index` is only read back
/// from it to move the dots and to know whether Next is the last call to action.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  /// Called when the user finishes or skips. `finished` is true when they
  /// walked every page, false when they skipped.
  final void Function(bool finished)? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller = PageController();

  /// Mirrors the PageView's position. Only ever written from
  /// `onPageChanged` - it is never the source of what is rendered, because
  /// that is what desynchronised the old version.
  int _index = 0;

  /// Set once onboarding has been recorded, so a double tap on the final button
  /// cannot record - and re-trigger - the transition twice.
  bool _recorded = false;

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Discover your fandoms',
      body: 'Deep dives, glossaries and beginner guides for every corner.',
      illustration: 'assets/onboarding/discover.svg',
    ),
    OnboardingPage(
      title: 'Never miss the moment',
      body: 'Discover conventions, screenings and meetups near you.',
      illustration: 'assets/onboarding/events.svg',
    ),
    OnboardingPage(
      title: 'Shop, save and ask',
      body: 'Collect what you love, keep it offline, and get a hand when stuck.',
      illustration: 'assets/onboarding/shop.svg',
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    // The controller is attached to the PageView, so it does need disposing -
    // but only once, and only because this State created it.
    _controller.dispose();
    super.dispose();
  }

  /// Records the outcome and leaves.
  ///
  /// The two outcomes are stored differently on purpose. Walking the whole
  /// tour is final. Skipping starts a 72-hour timer, so the tour is offered
  /// once more and then stops - treating a skip as a completion would mean a
  /// fan who swiped past it on day one never got another chance.
  ///
  /// The write is awaited before leaving. Firing it off unawaited would let the
  /// subtree swap in and the app tear down the isolate before the value landed,
  /// which on web loses the write entirely.
  Future<void> _finish(bool finished) async {
    if (_recorded) return;
    _recorded = true;

    if (finished) {
      await prefsMarkOnboardingCompleted();
    } else {
      await prefsMarkOnboardingSkipped();
    }

    widget.onFinished?.call(finished);
    if (mounted) Navigator.of(context).maybePop(finished);
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _complete() => _finish(true);

  void _skip() => _finish(false);

  /// Tapping a dot jumps straight to that page.
  ///
  /// `animateToPage` rather than `jumpToPage`, because jump takes no animation
  /// and would snap. Guarded on [hasClients] - a tap can land before the first
  /// layout, and driving an unattached controller throws.
  void _jumpTo(int index) {
    if (!_controller.hasClients) return;
    if (index < 0 || index >= _pages.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip sits top-right, out of the way of the illustration.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),

            // The carousel. Text and art both live in the page, so a swipe
            // moves everything together.
            //
            // One PageView, not two: a nested horizontal pager would compete
            // for the same drag gesture and the inner one would swallow the
            // swipe.
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _pages[index].build(context),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Dots(
                count: _pages.length,
                active: _index,
                onTap: _jumpTo,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Final page completes the tour; earlier pages just advance.
                  onPressed: _isLast ? _complete : _next,
                  child: Text(_isLast ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding page, as data plus its own widget.
///
/// Public because the artwork paths are worth asserting on in a test without
/// pumping a whole screen.
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String title;
  final String body;

  /// Asset path for this page's illustration.
  final String illustration;

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              // Contain, not cover: the illustrations are 800x520 and cropping
              // them would cut off the detail that makes them readable.
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                illustration,
                fit: BoxFit.contain,
                // A missing asset shows the tint rather than a red box, so a
                // broken path is quiet instead of alarming.
                placeholderBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, this.onTap});

  final int count;
  final int active;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return GestureDetector(
          onTap: onTap == null ? null : () => onTap!(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            // A touch target of at least 24px, even though the dot is 6px -
            // 6px is not tappable on a phone.
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            child: Container(
              height: 6,
              width: isActive ? 18 : 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.elevated,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}
