import 'paths_io.dart' if (dart.library.ui) 'paths_flutter.dart';

// A implicit getter for paths implementation
final pathsImpl = Paths();

class FactoryImpl {
  final Paths paths;

  const FactoryImpl(this.paths);
}
