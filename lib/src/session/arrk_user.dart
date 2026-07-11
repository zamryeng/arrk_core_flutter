/// Minimal identity of an authenticated user.
///
/// Products extend this with their own profile fields; the library only
/// needs the stable core the session foundation can rely on.
abstract class ArrkUser {
  final String id;
  final String email;

  ArrkUser({required this.id, required this.email});
}
