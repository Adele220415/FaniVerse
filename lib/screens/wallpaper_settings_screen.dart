import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/appearance_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/wallpaper/wallpaper.dart';
import '../core/wallpaper/wallpaper_painter.dart';
import '../widgets/fv_screen.dart';

/// Lets the reader pick the wallpaper shown behind the app.
///
/// Lives as its own screen rather than inside the settings sheet because the
/// settings sheet is a bottom sheet sized to its content, and a grid of
/// wallpaper thumbnails needs the full height of the page to be usable.
class WallpaperSettingsScreen extends StatefulWidget {
  const WallpaperSettingsScreen({super.key, required this.appearance});

  final AppearanceController appearance;

  @override
  State<WallpaperSettingsScreen> createState() => _WallpaperSettingsScreenState();
}

class _WallpaperSettingsScreenState extends State<WallpaperSettingsScreen> {
  bool _busy = false;
  String? _notice;

  /// The wallpaper the reader has highlighted but not yet applied.
  ///
  /// Selection is deliberately *not* applied on tap. Browsing presets should
  /// not repaint the app under the reader's finger, and without a pending
  /// state there is no way to change their mind before committing. Null means
  /// "no pending change", which is distinct from "pending the no-wallpaper
  /// option" - hence [hasPendingChange] rather than comparing to null.
  String? _pendingId;
  bool _hasPendingChange = false;

  /// True when the highlighted wallpaper differs from what is applied.
  bool get hasPendingChange => _hasPendingChange;

  @override
  Widget build(BuildContext context) {
    // The controller notifies on every change, and this screen is built under
    // the app-level AnimatedBuilder, so a rebuild is enough to reflect it.
    final appearance = widget.appearance;
    final selectedId = appearance.wallpaperId;

    // The highlighted tile is the pending one when there is a pending change,
    // otherwise the applied one - so a screen with no edits still shows where
    // it currently is.
    final highlightedId = _hasPendingChange ? _pendingId : selectedId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Wallpaper',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(
            'A picture behind the app. The colours around it are taken from the image, '
            'so the chrome shifts to match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _Option(
            label: 'No wallpaper',
            desc: 'Solid background.',
            // Highlighted when pending, so the row agrees with the tiles.
            selected: highlightedId == null,
            onTap: () => _stage(null),
            leading: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Presets',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),

          // A Wrap, not a GridView.
          //
          // GridView derives each cell's height from the width and a
          // childAspectRatio, so the cell is a fixed size while the tile
          // inside it is not - a two-line description needs a different height
          // from a one-line one. That mismatch is what produced the
          // "BOTTOM OVERFLOWED BY 4.3 PIXELS" stripes: the text block was
          // about a line taller than a square cell allowed. A Wrap lets each
          // tile be exactly as tall as its content, at any screen width.
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final tileWidth = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: 16,
                children: [
                  for (final item in kWallpaperPresets)
                    SizedBox(
                      width: tileWidth,
                      child: _WallpaperTile(
                        wallpaper: item,
                        selected: highlightedId == item.id,
                        onTap: () => _stage(item.id),
                      ),
                    ),
                  if (appearance.custom != null)
                    SizedBox(
                      width: tileWidth,
                      child: _WallpaperTile(
                        wallpaper: appearance.custom!,
                        selected: highlightedId == 'custom',
                        onTap: () => _stage('custom'),
                        onRemove: appearance.removeCustomWallpaper,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // The commit action. Disabled until something is actually chosen, so
          // it never looks like it does nothing.
          SizedBox(
            width: double.infinity,
            child: FvPrimaryButton(
              label: 'Apply wallpaper',
              onPressed: !hasPendingChange ? null : _apply,
            ),
          ),
          if (hasPendingChange) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _hasPendingChange = false;
                  _pendingId = null;
                }),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickImage,
            icon: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(_busy ? 'Preparing image...' : 'Use your own image'),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(
              _notice!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// Highlights a wallpaper without applying it.
  ///
  /// [id] is nullable because "No wallpaper" is a real choice; the separate
  /// [_hasPendingChange] flag is what distinguishes "highlighted nothing" from
  /// "highlighted the no-wallpaper option", since both would otherwise be null.
  void _stage(String? id) {
    final current = widget.appearance.wallpaperId;
    if (!mounted) return;

    setState(() {
      _notice = null;
      _pendingId = id;
      _hasPendingChange = id != current;
    });
  }

  /// Commits the highlighted wallpaper.
  void _apply() {
    if (!mounted) return;
    widget.appearance.setWallpaper(_pendingId);
    setState(() {
      _hasPendingChange = false;
      _pendingId = null;
      _notice = 'Wallpaper applied.';
    });
  }

  /// Picks an image and makes it the wallpaper.
  ///
  /// The decode-and-resize runs inside [AppearanceController], and the notice
  /// distinguishes "not saved" from "saved": a custom wallpaper that could not
  /// be persisted looks identical to one that could, until the next launch
  /// silently reverts it.
  Future<void> _pickImage() async {
    if (_busy) return;

    FilePickerResult? files;
    try {
      files = await FilePicker.platform.pickFiles(
        type: FileType.image,
        // Web hands back a path only, and reading a path there is impossible,
        // so the bytes have to be requested up front or the image is unusable.
        withData: true,
      );
    } catch (_) {
      if (mounted) setState(() => _notice = 'Could not open the file picker.');
      return;
    }

    if (files == null || files.files.isEmpty || !mounted) return;

    setState(() {
      _busy = true;
      _notice = null;
    });

    try {
      // Bytes arrive in the result when the platform can supply them; where it
      // cannot, there is no portable fallback, so this is reported rather than
      // failing deep inside the decoder.
      final picked = files.files.first;
      final bytes = picked.bytes;
      if (bytes == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _notice = 'That image could not be read. Try a different file.';
        });
        return;
      }

      final persisted = await widget.appearance.addCustomWallpaper(bytes);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = persisted
            ? null
            : 'Image is too large to save, so it will reset when you reopen the app. '
                'Try a smaller picture.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = 'That file could not be read as an image.';
      });
    }
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
    required this.leading,
  });

  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusTile),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 44, height: 44, child: leading),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({
    required this.wallpaper,
    required this.selected,
    required this.onTap,
    this.onRemove,
  });

  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // The tile is sized by its content. The old fixed 110px image plus a
        // two-line description needed a height the surrounding grid cell could
        // not always give it, which is what overflowed.
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(
                // Scales with the tile width instead of a fixed 110, so the
                // thumbnail keeps its shape at any grid size.
                aspectRatio: 16 / 10,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _Preview(wallpaper: wallpaper),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                ),
              if (onRemove != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            wallpaper.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          // One line, not two. A second line is what made the tile taller than
          // the cell; the full text still wraps rather than truncating
          // mid-word if the tile is wide.
          Text(
            wallpaper.desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A thumbnail of the wallpaper.
///
/// The painted presets use [WallpaperPainter] in preview mode, which draws a
/// reduced star count and so is cheap enough to render in a grid of them. A
/// custom image decodes its base64 again per tile; there is at most one such
/// tile, so the cost does not scale.
class _Preview extends StatelessWidget {
  const _Preview({required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    if (wallpaper.preset != null) {
      return CustomPaint(painter: WallpaperPainter(wallpaper.preset!, preview: true));
    }

    final dataUrl = wallpaper.dataUrl;
    if (dataUrl == null) return const ColoredBox(color: AppColors.elevated);

    final index = dataUrl.indexOf('base64,');
    if (index == -1) return const ColoredBox(color: AppColors.elevated);

    return Image.memory(
      // decodeDataUrl cannot fail here: the value round-tripped through
      // SharedPreferences, and a bad one falls back to a placeholder below.
      _decode(dataUrl.substring(index + 7)) ?? Uint8List(0),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.elevated),
    );
  }

  Uint8List? _decode(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }
}
