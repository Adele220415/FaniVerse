import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A slim banner shown while the device has no network.
///
/// Uses the real connectivity signal rather than inferring offline-ness from a
/// failed request: a request can fail for a dozen reasons (a permission error,
/// a rate limit) and none of them mean the user is offline.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, this.message, this.cachedAt});

  /// Overrides the default copy, e.g. to mention that a cached feed is showing.
  final String? message;

  /// When set, the banner says how old the cached data is.
  final DateTime? cachedAt;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    // Initial state, so the banner is correct on first frame instead of
    // flashing online then flipping.
    Connectivity().checkConnectivity().then(_apply);

    Connectivity().onConnectivityChanged.listen((results) {
      _apply(results);
    });
  }

  void _apply(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline != _offline && mounted) {
      setState(() => _offline = offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return const SizedBox.shrink();

    final age = widget.cachedAt == null ? null : _age(widget.cachedAt!);
    final text = widget.message ??
        (age == null
            ? 'You are offline.'
            : 'You are offline. Showing saved content from $age.');

    return Container(
      width: double.infinity,
      color: AppColors.warning.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Short relative age. Precision past "a day" is not useful here.
  String _age(DateTime then) {
    final diff = DateTime.now().difference(then);
    if (diff.inMinutes < 1) return 'moments ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
