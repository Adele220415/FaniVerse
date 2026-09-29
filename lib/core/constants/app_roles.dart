/// The app's role vocabulary.
///
/// There are exactly two roles: [fan] and [admin]. An earlier revision shipped a
/// `reader / writer / editor / moderator` ladder, but none of those rungs were
/// ever read by any code - they were decoration on seeded documents. Collapsing
/// them means a role is now something the app actually branches on.
///
/// ## Legacy values
///
/// Seeded and pre-existing documents still carry the old strings. [normalize]
/// maps every one of them onto [fan], so a document is never in a state the
/// app cannot classify. Run `seed/backfill-users.mjs` to rewrite them in place.
class AppRoles {
  const AppRoles._();

  /// The role every ordinary account has. Also the fallback for any document
  /// whose `role` is missing or unrecognised, so an unparseable value can
  /// never accidentally grant admin.
  static const String fan = 'fan';

  /// The single privileged role. There is exactly one admin account; see
  /// [adminEmail].
  static const String admin = 'admin';

  static const List<String> all = [fan, admin];

  /// The address that identifies the one admin account.
  ///
  /// This is an *identifier*, not a credential. It ships in the binary and is
  /// therefore public - it is used to match the signed-in account against the
  /// `role` field written out-of-band by `seed/grant-admin.mjs`, never to
  /// decide privilege on its own. The password deliberately does not live in
  /// the app: a credential compiled into an APK is readable by anyone who
  /// unpacks it.
  static const String adminEmail = 'adminpage@faniverse.com';

  static bool isAdmin(String? role) => role == admin;

  static bool isFan(String? role) => role == fan;

  /// Maps any stored value onto the two-role vocabulary.
  ///
  /// Anything that is not [admin] becomes [fan]. This is deliberately a
  /// whitelist rather than a blacklist: an unknown or corrupt value must fail
  /// closed, never open.
  static String normalize(String? role) {
    if (role == null) return fan;
    return role.trim().toLowerCase() == admin ? admin : fan;
  }

  /// True if [value] is already in the canonical vocabulary.
  static bool isValid(String? value) {
    if (value == null) return false;
    return all.contains(value.trim().toLowerCase());
  }
}
