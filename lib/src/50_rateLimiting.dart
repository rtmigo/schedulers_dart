// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:pedantic/pedantic.dart';

import '20_base.dart';

/// Launches callbacks asynchronously, guided by the rule "no more than N tasks in a certain
/// period of time".
///
/// For example, no more than three tasks per second. The first three will be executed
/// immediately, and the rest will wait, then the next three will be executed - and so on.
///
/// The object is useful, for example, for accessing an API with a limit of "no more than 5
/// requests per minute".
class RateLimitingScheduler implements PriorityScheduler {
  final HeapPriorityQueue<Task> _queue = HeapPriorityQueue<Task>();

  @override
  int get queueLength => this._queue.length;

  final int n;
  final Duration per;

  RateLimitingScheduler(this.n, this.per);

  final Queue<Stopwatch> _recentTimes = Queue<Stopwatch>();

  @override
  Task<T> run<T>(GetterFunc<T> callback, [int priority = 0]) {
    Task<T>? result;
    result = Task<T>(callback, priority);
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
          unawaited(Future(() {
            try {
              task.completer.complete(task.callback());
            } catch (e, stacktrace) {
              task.completer.completeError(e, stacktrace);
            }
          }));
        }
      }
    } finally {
      this._isLooping = false;
    }
  }

  @override
  void cancel(Task t) {
    if (!this._queue.remove(t)) {
      throw ArgumentError('Task not found.');
    }
  }
}
