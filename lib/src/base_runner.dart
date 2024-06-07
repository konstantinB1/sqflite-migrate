/// A base interface for migration runners. Right now it only has
/// basic migrate/up commands, in future we might opt in for
/// status based commands, either here or extend it on a base
/// standalone reporter interface
abstract class BaseRunner {
  /// By default run all the migrations if [until] is not provided
  Future<void> migrate({bool force = false, int until = -1});

  /// By default rollback all if [until] is not provided
  Future<void> rollback({bool force = false, int until = -1});
}
