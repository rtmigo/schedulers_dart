// import 'dart:async';
// import 'dart:collection';
//
// import 'package:collection/priority_queue.dart';
//
// import 'b_base.dart';
//
//
// // // TODO add to schedulers
// //
// // abstract class _Task<R> {
// //   Future<R> get result;
// //
// //   bool get isCompleted;
// // }
// //
// // class _CompletableTask<R> implements _Task<R> {
// //   final Future<R> Function() function;
// //
// //   @override
// //   Future<R> get result => completer.future;
// //
// //   @override
// //   bool get isCompleted => completer.isCompleted;
// //
// //   Completer<R> completer = Completer<R>();
// //
// //   _CompletableTask(this.function);
// // }
//
// class ConcurrentScheduler implements PriorityScheduler {
//   final int concurrency;
//   final _tasks = HeapPriorityQueue<PriorityTask<dynamic>>();
//
//   ConcurrentScheduler({this.concurrency = 8});
//
//   // _Task<R> _add(final Future<R> Function() func) {
//   //   final t = _CompletableTask(func);
//   //   _tasks.addLast(t);
//   //   _maybeRunTasks();
//   //   return t;
//   // }
//
//   @override
//   Task<R> run<R>(final GetterFunc<R> callback, [final int priority = 0]) {
//     final newTask = PriorityTask(callback, priority,
//         onCancel: (final InternalTask<R> canceledTask) {
//           if (!this._tasks.remove(canceledTask as PriorityTask<dynamic>)) {
//             throw ArgumentError('Task not found.');
//           }
//         });
//
//     _tasks.add(newTask);
//     _maybeRunTasks();
//     return newTask;
//   }
//
//   //Future<R> run(final Future<R> Function() func) => _add(func).result;
//
//   int _currentlyRunning = 0;
//   int get currentlyRunning => _currentlyRunning;
//
//   /// Это синхронная функция, которая запускает задачи асинхронно рекурсивно.
//   /// После выполнения каждая задача снова вызывает [_maybeRunTasks].
//   ///
//   /// Количество вложенных вызовов может почти достигать длины длины очереди.
//   /// Тест с миллионом запускаемых задач показал, что это не приводит к
//   /// проблемам вроде переполнения стека.
//   void _maybeRunTasks() {
//
//     assert (_currentlyRunning<=concurrency);
//
//     while (_currentlyRunning < concurrency && _tasks.isNotEmpty) {
//       final runMe = _tasks.removeFirst();
//       _currentlyRunning += 1;
//       Future.microtask(() async {
//         assert(!runMe.runIfNotCanceled());
//
//         try {
//           assert(!runMe.completer.isCompleted);
//           final r = await runMe.function();
//           runMe.completer.complete(r);
//         } catch (error, trace) {
//           assert(!runMe.completer.isCompleted);
//           runMe.completer.completeError(error, trace);
//         }
//
//         assert(runMe.completer.isCompleted);
//       }).whenComplete(() {
//         assert(runMe.isCompleted);
//         _currentlyRunning--;
//         assert(_currentlyRunning >= 0);
//         _maybeRunTasks();
//       });
//     }
//
//     assert(_currentlyRunning==concurrency || _tasks.isEmpty);
//   }
//
//   @override
//   // TODO: implement queueLength
//   int get queueLength => throw UnimplementedError();
//
//
// }
