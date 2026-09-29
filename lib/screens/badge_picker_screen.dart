import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/fan_badge.dart';
import '../services/badge_service.dart';
import '../widgets/fan_badge_chip.dart';
import '../widgets/fv_screen.dart';

/// The badge wall, per the "Claim your first badge" screen in the designs.
///
/// The difference from that mockup: badges are **earned from real activity**
/// rather than picked. A locked badge shows its progress, and only the ones
/// already unlocked can be pinned as the profile's featured badge. That keeps
/// the wall meaningful - a badge anyone can select is decoration.
class BadgePickerScreen extends StatefulWidget {
  const BadgePickerScreen({super.key, this.userId, this.service, this.allowPinning = true});

  final String? userId;
  final BadgeService? service;

  /// False on someone else's profile, where the wall is read-only.
  final bool allowPinning;

  @override
  State<BadgePickerScreen> createState() => _BadgePickerScreenState();
}

class _BadgePickerScreenState extends State<BadgePickerScreen> {
  late final BadgeService _service = widget.service ?? BadgeService();

  bool _isLoading = true;
  String? _error;
  List<FanBadge> _badges = const [];
  String? _pinned;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = widget.userId ?? _service.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Sign in to see your badges';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _service.watchBadges(uid).listen(
      (badges) {
        if (!mounted) return;
        setState(() {
          _badges = badges;
          _isLoading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      },
    );

    if (widget.allowPinning) {
      _service.watchPinnedBadge(uid).listen((pinned) {
        if (mounted) setState(() => _pinned = pinned);
      });
    }
  }

  Future<void> _pin(FanBadge badge) async {
    final uid = widget.userId ?? _service.currentUser?.uid;
    if (uid == null) return;

    // Tapping the pinned badge again unpins it.
    final target = _pinned == badge.id ? null : badge.id;

    final result = await _service.pinBadge(uid, target);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _pinned = target);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(target == null ? 'Badge removed from your profile' : '${badge.label} pinned'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Could not update your badge'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final earned = _badges.where((b) => b.unlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Badges',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? FvEmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load badges',
                  message: _error,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    const Text(
                      'Show the community what kind of fan you are.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    // A summary strip, so progress is legible at a glance.
                    _ProgressSummary(earned: earned, total: _badges.length),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.86,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _badges.length,
                      itemBuilder: (context, index) {
                        final badge = _badges[index];
                        final isPinned = widget.allowPinning && _pinned == badge.id;
                        return _BadgeTile(
                          badge: badge,
                          pinned: isPinned,
                          onTap: widget.allowPinning && badge.unlocked ? () => _pin(badge) : null,
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : earned / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earned',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                '$earned of $total',
                style: const TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.elevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Badges unlock from what you post and save. Pin one to your profile.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.pinned, this.onTap});

  final FanBadge badge;
  final bool pinned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: pinned ? AppColors.primaryTint : AppColors.elevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pinned ? AppColors.primary : AppColors.border,
              width: pinned ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FanBadgeChip(badge: badge, size: 44, showTooltip: false),
              const SizedBox(height: 10),
              Text(
                badge.label,
                style: TextStyle(
                  color: badge.unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                badge.unlocked
                    ? (pinned ? 'Pinned' : 'Unlocked')
                    : '${badge.progress}/${badge.target}',
                style: TextStyle(
                  color: pinned
                      ? AppColors.primaryLight
                      : (badge.unlocked ? AppColors.success : AppColors.textTertiary),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!badge.unlocked) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: badge.ratio,
                    minHeight: 3,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
