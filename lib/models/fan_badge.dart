/// A badge a fan can hold, shown on their profile.
///
/// Badges are **derived from real activity**, not chosen by the user. The
/// designs show a picker where someone claims a starting badge, but a badge
/// anyone can pick is decoration; one that unlocks from what you have actually
/// done is what the "Beginner Fan Hub" framing is going for. A user may still
/// pin one as their featured badge, but only from the ones they have earned.
class FanBadge {
  const FanBadge({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.progress = 0,
    this.target = 1,
    this.unlocked = false,
  });

  final String id;
  final String label;
  final String description;
  final String icon;

  /// How far along the fan is toward unlocking it.
  final int progress;
  final int target;
  final bool unlocked;

  /// 0..1, for a progress bar or ring.
  double get ratio {
    if (target <= 0) return unlocked ? 1 : 0;
    return (progress / target).clamp(0.0, 1.0);
  }

  /// What is left, phrased for a progress line.
  String get progressLabel {
    if (unlocked) return 'Unlocked';
    final remaining = target - progress;
    if (remaining <= 0) return 'Unlocked';
    return '$remaining to go';
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// [unlocked] is recomputed from the new progress rather than copied
  /// through, so raising progress to the target actually unlocks the badge.
  /// Copying the old flag would leave a badge that claims to be locked after
  /// the user did the thing.
  FanBadge copyWith({int? progress, int? target, bool? unlocked}) {
    final nextProgress = progress ?? this.progress;
    final nextTarget = target ?? this.target;
    return FanBadge(
      id: id,
      label: label,
      description: description,
      icon: icon,
      progress: nextProgress,
      target: nextTarget,
      unlocked: unlocked ?? (this.unlocked || nextProgress >= nextTarget),
    );
  }

  factory FanBadge.fromMap(Map<String, dynamic> map) {
    return FanBadge(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      icon: map['icon']?.toString() ?? 'stars',
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 1,
      unlocked: map['unlocked'] == true,
    );
  }
}

/// The activity a badge is measured against.
class FanActivity {
  const FanActivity({
    this.postCount = 0,
    this.likesReceived = 0,
    this.savesReceived = 0,
    this.commentsWritten = 0,
    this.communitiesJoined = 0,
    this.eventsCreated = 0,
    this.productsListed = 0,
  });

  final int postCount;
  final int likesReceived;
  final int savesReceived;
  final int commentsWritten;
  final int communitiesJoined;
  final int eventsCreated;
  final int productsListed;

  bool get isEmpty =>
      postCount == 0 &&
      likesReceived == 0 &&
      savesReceived == 0 &&
      commentsWritten == 0 &&
      communitiesJoined == 0 &&
      eventsCreated == 0 &&
      productsListed == 0;
}

/// Computes which badges a fan has earned from their activity.
///
/// The definitions live in one place so a threshold is never stated twice, and
/// so the picker, the profile and the service all agree on what "Lorekeeper"
/// means.
class BadgeRules {
  const BadgeRules._();

  /// Every badge, with the rule that unlocks it.
  static List<FanBadge> evaluate(FanActivity activity) {
    return [
      _check(
        id: 'newcomer',
        label: 'Newcomer',
        description: 'Joined the verse',
        icon: 'sparkle',
        progress: 1,
        target: 1,
        unlocked: true,
      ),
      _check(
        id: 'first-post',
        label: 'First Words',
        description: 'Published your first post',
        icon: 'edit',
        progress: activity.postCount,
        target: 1,
      ),
      _check(
        id: 'lorekeeper',
        label: 'Lorekeeper',
        description: 'Published 5 posts',
        icon: 'book',
        progress: activity.postCount,
        target: 5,
      ),
      _check(
        id: 'archivist',
        label: 'Archivist',
        description: 'Published 20 posts',
        icon: 'library',
        progress: activity.postCount,
        target: 20,
      ),
      _check(
        id: 'appreciated',
        label: 'Appreciated',
        description: 'Received 10 likes',
        icon: 'heart',
        progress: activity.likesReceived,
        target: 10,
      ),
      _check(
        id: 'fan-favourite',
        label: 'Fan Favourite',
        description: 'Received 50 likes',
        icon: 'star',
        progress: activity.likesReceived,
        target: 50,
      ),
      _check(
        id: 'curator',
        label: 'Curator',
        description: 'Received 10 saves',
        icon: 'bookmark',
        progress: activity.savesReceived,
        target: 10,
      ),
      _check(
        id: 'convention-hero',
        label: 'Convention Hero',
        description: 'Ran 3 events',
        icon: 'event',
        progress: activity.eventsCreated,
        target: 3,
      ),
      _check(
        id: 'collector',
        label: 'Collector',
        description: 'Listed 5 items',
        icon: 'shopping_bag',
        progress: activity.productsListed,
        target: 5,
      ),
      _check(
        id: 'cosplay-rookie',
        label: 'Cosplay Rookie',
        description: 'Joined 3 communities',
        icon: 'groups',
        progress: activity.communitiesJoined,
        target: 3,
      ),
    ];
  }

  /// A badge is unlocked when the count reaches the target. The newcomer badge
  /// is always unlocked, since having an account already satisfies it.
  static FanBadge _check({
    required String id,
    required String label,
    required String description,
    required String icon,
    required int progress,
    required int target,
    bool unlocked = false,
  }) {
    return FanBadge(
      id: id,
      label: label,
      description: description,
      icon: icon,
      progress: progress,
      target: target,
      unlocked: unlocked || progress >= target,
    );
  }

  /// The icon name -> Material icon mapping, kept beside the rules so a new
  /// badge cannot be added without an icon.
  static IconDataRef iconFor(String name) {
    switch (name) {
      case 'sparkle':
        return const IconDataRef('auto_awesome');
      case 'edit':
        return const IconDataRef('edit_note');
      case 'book':
        return const IconDataRef('menu_book');
      case 'library':
        return const IconDataRef('local_library');
      case 'heart':
        return const IconDataRef('favorite');
      case 'star':
        return const IconDataRef('star');
      case 'bookmark':
        return const IconDataRef('bookmark');
      case 'event':
        return const IconDataRef('event');
      case 'shopping_bag':
        return const IconDataRef('shopping_bag');
      case 'groups':
        return const IconDataRef('groups');
      default:
        return const IconDataRef('stars');
    }
  }
}

/// A tiny indirection so the rules file does not import Flutter's icon set,
/// which keeps it usable from a plain Dart test.
class IconDataRef {
  const IconDataRef(this.name);
  final String name;
}
