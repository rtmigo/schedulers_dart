// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:collection/collection.dart';

import '20_base.dart';

/// Runs tasks asynchronously, maintaining a fixed time interval between starts.
///
/// For example, this allows to distribute many small tasks over time, so they will not create
/// a noticeable lag in the program interface. It is better to run 100 tasks of 10 milliseconds
/// each, redrawing frames between them, than to run the tasks all at once, freezing the interface
/// for a second.
class IntervalScheduler implements PriorityScheduler {
  IntervalScheduler({this.delay = const Duration(seconds: 1)});

  final PriorityQueue<PriorityTask> _tasks = HeapPriorityQueue<PriorityTask>();
  final Duration delay;
  bool _scheduled = false;

  @override
  int get queueLength => this._tasks.length;

  bool get isComplete => this._tasks.length > 0;

  Completer _completer = Completer();

  Future<void> get completed => this._completer.future;

  /// Notifies the scheduler that it should run the callback sometime. The actual call will occur
  /// asynchronously at the time selected by the scheduler.
  @override
  Task<T> run<T>(GetterFunc<T> callback, [int priority = 0]) {
    if (this._tasks.length <= 0) {
      this._completer = Completer();
    }

    var t = PriorityTask(callback, priority, onCancel: (tsk) {
      if (!this._tasks.remove(tsk)) {
        throw ArgumentError('Task not found.');
      }
    });

    _tasks.add(t);
    this._runRunnerLater();

    return t;
  }

  bool _disposed = false;
  void dispose() {
    _disposed = true;
    for (var t in _tasks.toList()) {
      t.willRun = false; // todo unit test
    }
    _tasks.clear();
  }

  void _runner() {
    this._scheduled = false;

    if (this._disposed) {
      if (!this._completer.isCompleted) {
        this._completer.complete();
      }
      return;
    }

    try {
      _tasks.removeFirst().runIfNotCanceled();
    } finally {
      if (this._tasks.length <= 0) {
        this._completer.complete();
      }

      this._runRunnerLater();
    }
  }

  void _runRunnerLater() {
    if (!this._scheduled && _tasks.length > 0) {
      //if (this.tasks.length==1)
      //this.complete = Completer();
      Future.delayed(this.delay, this._runner);
      this._scheduled = true;
    }
  }
}
