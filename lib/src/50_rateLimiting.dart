// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:pedantic/pedantic.dart';

import '20_base.dart';

/// Runs no more than N tasks in a certain period of time.
///
/// For example, no more than three tasks per second. The first three will be executed
/// immediately, and the rest will wait, then the next three will be executed - and so on.
///
/// The object is useful, for example, for accessing an API with a limit of "no more than 5
/// requests per minute".
class RateScheduler implements PriorityScheduler {
  final HeapPriorityQueue<PriorityTask> _queue = HeapPriorityQueue<PriorityTask>();

  // todo add dispose

  @override
  int get queueLength => this._queue.length;

  final int n;
  final Duration per;

  RateScheduler(this.n, this.per);

  final Queue<Stopwatch> _recentTimes = Queue<Stopwatch>();

  /// Notifies the scheduler that it should run the callback sometime. The actual call will occur
  /// asynchronously at the time selected by the scheduler.
  @override
  Task<T> run<T>(GetterFunc<T> callback, [int priority = 0]) {
    PriorityTask<T>? result;
    result = PriorityTask<T>(callback, priority, onCancel: (tsk) {
      if (!this._queue.remove(tsk)) {
        throw ArgumentError('Task not found.');
      }
    });
    _queue.add(result);
    this._loopAsync();
    return result;
  }

  void runEmpty() => this._loopAsync();

  bool _isLooping = false;

  void stop() {
    this._breakLoopNow = true;
  }

  bool _breakLoopNow = false;

  Future _loopAsync() async {
    // предотвращаем параллельную работу нескольких _loop
    if (this._isLooping) {
      return;
    }

    this._isLooping = true;

    try {
      while (this._queue.length > 0) {
        if (_breakLoopNow) {
          _breakLoopNow = false;
          break;
        }

        if (this._recentTimes.length >= n) {
          // we will wail the oldest task to become "too old"
          final delay = this.per - this._recentTimes.first.elapsed;
          if (delay > const Duration(seconds: 0)) {
            await Future.delayed(delay);
            // sometimes this pause ends a few milliseconds earlier than expected
            // (the actual delay is shorter than specified by the argument).
            //
            // It's not a problem. The code below will just determine that it is
            // not ready to start tasks. We'll come back here again and pause again.
          }
        }

        // removing too old tasks
        while (this._recentTimes.isNotEmpty 
               && this._recentTimes.first.elapsed >= this.per) {
          this._recentTimes.removeFirst();
        }

        while (this._recentTimes.length < n && this._queue.isNotEmpty) {
          // running new task
          var task = this._queue.removeFirst();
          // remembering task start time
          this._recentTimes.add(Stopwatch()..start());
          unawaited(Future(()=>task.runIfNotCanceled()));
        }
      }
    } finally {
      this._isLooping = false;
    }
  }

  // @override
  // void cancel(Task t) {
  //
  // }
}
