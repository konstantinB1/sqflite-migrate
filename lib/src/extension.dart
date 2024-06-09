/// Utility class to differentiate
/// file extension types to be
/// associated with different parsers
///
/// Currently its only .sql
enum Extension {
  sql('.sql');

  final String value;

  const Extension(this.value);
}
