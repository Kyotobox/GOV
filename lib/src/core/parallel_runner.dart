import 'dart:async';
import 'dart:isolate';

/// ParallelRunner: Executes multiple tasks in parallel using Dart Isolates.
class ParallelRunner {
  /// Runs a list of async functions in parallel.
  /// Note: Isolate.run() is useful for CPU-bound tasks.
  /// For I/O bound tasks, standard Future.wait is often sufficient,
  /// but here we provide a structure for compute-heavy checks (like hashing).
  Future<List<T>> runParallel<T>(List<Future<T> Function()> tasks) async {
    // In Dart, simply awaiting multiple futures is often enough unless the tasks are sync/blocking.
    // For this implementation, we use Future.wait to parallelize I/O operations.
    return Future.wait(tasks.map((task) => task()));
  }

  /// Example of offloading heavy hashing to an isolate.
  static Future<T> runCompute<T>(FutureOr<T> Function() computation) async {
    return await Isolate.run(computation);
  }
}
