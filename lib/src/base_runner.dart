abstract class BaseRunner {
  Future<void> migrate({bool force = false, int until = -1});
  Future<void> rollback({bool force = false, int until = -1});
}
