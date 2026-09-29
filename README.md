# faniverse_main

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Media uploads (Cloudinary + Firestore)

Users pick an image, video or audio file from their device, it is uploaded to
Cloudinary, and the returned `https://res.cloudinary.com/...` URL is written to
Firestore.

```
pick file  ->  POST https://api.cloudinary.com/v1_1/<cloud>/<resource_type>/upload
                 (file + upload_preset, no API secret)
           ->  read secure_url from the JSON response
           ->  write that URL to Firestore
```

### Files

| File | Role |
| --- | --- |
| `lib/core/constants/cloudinary_config.dart` | Build-time config + `isConfigured` guard |
| `lib/services/cloudinary_service.dart` | Raw upload, returns `secure_url` / `public_id` |
| `lib/services/media_upload_service.dart` | Pick + upload + persist, image/video/audio |
| `lib/widgets/media_upload_tile.dart` | Reusable upload slot UI |

### One-time Cloudinary setup

1. Sign in at [cloudinary.com](https://cloudinary.com) and note your **cloud
   name** (Settings > Account, or the `cloud_name` in your dashboard URL).
2. Go to **Settings > Upload > Upload presets > Add upload preset**.
3. Set **Signing mode** to **Unsigned**.
4. Set **Preset name** to something like `faniverse_unsigned`.
5. Leave the folder field empty, or set it to `faniverse`. Do **not** tick
   "Save preset with modifications as a template" unless you want the app's
   folders ignored.
6. Under **Restrictions**, it is worth adding:
   - `Allowed formats`: `jpg, jpeg, png, webp, gif, mp4, mov, webm, mp3, m4a, wav`
   - `Max file size`: the largest file you intend to accept (see the limits in
     `MediaKind`).
   - Optionally `Allowed resources` to pin `image` and `video` only.
7. Save the preset.

The preset name is the only credential the app holds. It grants upload-only
access and nothing else, which is exactly why it is safe in a client binary.

### Running with the preset

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_PRESET=faniverse_unsigned
```

Without those flags the app still builds and runs: upload slots are disabled,
a banner on the Create Content screen explains why, and the "Paste a URL
instead" panel remains available.

### Platform support

The upload path is deliberately free of `dart:io` so it works on Android, iOS,
Windows, macOS, Linux **and the web**. The pickers hand back an `XFile` and the
service reads it through `XFile.readAsBytes()`, because on the web the picker
returns an in-memory blob with no filesystem path behind it - `File(path)` throws
`Unsupported operation: _Namespace` there. Two details that this forces:

- The multipart `filename` is always set explicitly, since on the web it is the
  only filename available.
- `XFile.name` is not trusted. On native it is derived from the path and split
  only on the platform separator, and `XFile.fromData` discards its `name`
  argument there entirely. `_safeFilename` reduces it to a bare basename and
  synthesises an extension when needed, so a local directory path is never
  published as a Cloudinary asset name.

### Where the URL is stored

| Upload | Firestore path |
| --- | --- |
| Cover image | `content/{id}.imageUrl` (and `.bannerUrl`) |
| Video | `content/{id}.videoUrl` |
| Audio | `content/{id}.audioUrl` |
| Profile picture | `users/{uid}.profileImage` |

The three media fields are lists, matching what `ContentItem.fromFirebase`
already parses, and `bannerUrl` is kept in sync because other screens still
read it.

### Why there is no API secret anywhere in this code

Flutter compiles Dart into the app binary, so a secret placed in a
`String.fromEnvironment` or a Dart constant is trivially recovered by anyone
who decompiles the APK/IPA. Signed Cloudinary uploads therefore require a
server or Cloud Function that holds the API secret and returns a signature -
`CloudinaryService.deleteAsset` is stubbed out to say exactly that, rather than
pretending a client can do it. If you later need deletes or transformations
that the preset does not allow, that signed endpoint is the place to add.

