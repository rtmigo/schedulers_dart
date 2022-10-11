import 'dart:async';

import 'package:collection/collection.dart';

import 'b_base.dart';

class ConcurrentScheduler implements PriorityScheduler {
  final int concurrency;
  final _tasks = HeapPriorityQueue<PriorityTask<dynamic>>();

  ConcurrentScheduler({this.concurrency = 8});

  @override
  Task<R> run<R>(final GetterFunc<R> callback, [final int priority = 0]) {
    final newTask = PriorityTask(callback, priority,
        onCancel: (final InternalTask<dynamic> t) =>
            removeTaskFromQueue(_tasks, t));

    _tasks.add(newTask);
    _maybeRunTasks();
    return newTask;
  }

  //Future<R> run(final Future<R> Function() func) => _add(func).result;

  int _currentlyRunning = 0;

  int get currentlyRunning => _currentlyRunning;

  /// Это синхронная функция, которая запускает задачи асинхронно рекурсивно.
  /// После выполнения каждая задача снова вызывает [_maybeRunTasks].
  ///
  /// Количество вложенных вызовов может почти достигать длины длины очереди.
  /// Тест с миллионом запускаемых задач показал, что это не приводит к
  /// проблемам вроде переполнения стека.
  void _maybeRunTasks() {
    assert(_currentlyRunning <= concurrency);

    while (_currentlyRunning < concurrency && _tasks.isNotEmpty) {
      final runMe = _tasks.removeFirst();
      _currentlyRunning += 1;
      Future.microtask(() async {
        await runMe.runIfNotCanceled();
      }).whenComplete(() {
        _currentlyRunning--;
        assert(_currentlyRunning >= 0);
        _maybeRunTasks();
      });
    }

    assert(_currentlyRunning == concurrency || _tasks.isEmpty);
  }

  @override
  // TODO: implement queueLength
  int get queueLength => _tasks.length;
}
