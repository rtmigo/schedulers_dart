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

  final PriorityQueue<Task> _tasks = HeapPriorityQueue<Task>();
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

    var t = Task(callback, priority);

    _tasks.add(t);
    this._runRunnerLater();

    return t;
  }

  @override
  void cancel(Task t) {
    if (!this._tasks.remove(t)) {
      throw ArgumentError('Task not found.');
    }
  }

  void _runner() {
    this._scheduled = false;
    try {
      _tasks.removeFirst().callback();
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

//
// /// For some reason in GitHub actions when I just [await Future.delayed(xxx)], it takes
// /// a little less time, than xxx. This function fixes the problem. It may take a little more time,
// /// but not less
// Future<void> pauseAtLeast(Duration d) async {
//   if (d.isNegative) {
//     return;
//   }
//
//   Stopwatch timeTaken = Stopwatch()..start();
//
//   while (true) {
//     final delay = d - timeTaken.elapsed;
//     if (delay <= const Duration(microseconds: 0)) {
//       return;
//     }
//
//     await Future.delayed(d);
//   }
// }
//
//
