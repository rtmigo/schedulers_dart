// SPDX-FileCopyrightText: (c) 2022 Artsiom iG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'b_base.dart';

/// Limits the number of tasks running at the same time. This is somewhat
/// similar to using a thread pool or process pool. But it just runs async
/// functions.
class ParallelScheduler implements PriorityScheduler {
  final int max;
  final _tasks = HeapPriorityQueue<PriorityTask<dynamic>>();

  /// [max] sets the maximum number of tasks that can be run simultaneously.
  ParallelScheduler(this.max);

  @override
  Task<R> run<R>(final GetterFunc<R> callback, [final int priority = 0]) {
    final newTask = PriorityTask(callback, priority,
        onCancel: _tasks.removeOrThrow);

    _tasks.add(newTask);
    _maybeRunTasks();
    return newTask;
  }

  int _currentlyRunning = 0;

  @internal
  int get currentlyRunning => _currentlyRunning;

  /// Это синхронная функция, которая запускает задачи асинхронно рекурсивно.
  /// После выполнения каждая задача снова вызывает [_maybeRunTasks].
  ///
  /// Количество вложенных вызовов может почти достигать длины длины очереди.
  /// Тест с миллионом запускаемых задач показал, что это не приводит к
  /// проблемам вроде переполнения стека.
  void _maybeRunTasks() {
    assert(_currentlyRunning <= max);

    while (_currentlyRunning < max && _tasks.isNotEmpty) {
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

    assert(_currentlyRunning == max || _tasks.isEmpty);
  }

  @override
  int get queueLength => _tasks.length;
}
