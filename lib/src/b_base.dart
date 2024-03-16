// SPDX-FileCopyrightText: (c) 2021 Artsiom iG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'a_unlimited.dart';

typedef GetterFunc<R> = FutureOr<R> Function();

@internal
typedef CancelFunc = void Function(InternalTask<dynamic>);

class TaskCanceled {}

abstract class Task<R> {
  Future<R> get result;

  /// Returns true before the task starts. Returns false if the task has already
  /// been completed.
  ///
  /// By setting this value to false, you can cancel the upcoming start of the
  /// task.
  bool get willRun;

  set willRun(final bool x);
}

class InternalTask<R> extends Task<R> {
  InternalTask(this._block, {this.onCancel});

  final GetterFunc<R> _block;

  /// Called when used [cancel]s the task. It helps the scheduler to remove the
  /// task from the queue, if needed.
  @internal
  final CancelFunc? onCancel;

  @internal
  Future<void> runIfNotCanceled() async {
    if (!this._willRun) {
      return;
    }

    try {
      this._readyResult = await this._block();
      assert(!this._haveResult);
      this._haveResult = true;
      assert(_completer == null || !_completer!.isCompleted);
      this._completer?.complete(this._readyResult);
    } catch (e, stacktrace) {
      // when the _block throws error:
      //
      // (1) If user never asked for .result, we did not even created a
      // Completer. The exception will be rethrown to the Zone (and maybe never
      // handled). But we'll see it in the logs.
      //
      // (2a) If user asked for .result and started awaiting it, the Completer
      // will pass error the the waiting code. So the exception may be handled
      // by the user, if he `try { await task.result } catch { }`
      //
      // (2b) If the uses asked for .result, but not started awaiting it, we
      // created the Completer and will pass the exception to it. The Completer
      // knows that nobody awaits its future. So it throws the error to the Zone
      // (like if we never created the completer).
      //
      // In all three cases the exception is "thrown" somewhere: either to
      // the zone or to the awaiting code.
      //
      // In (1) and (2b) we just throw exception to the zone, with the
      // completer, or without it. So why don't we just create Completer
      // unconditionally and always pass results to it?
      //
      // That's because of canceling tasks. If user created a task, started
      // awaiting the result (2a), and then canceled the task, then he WANTS the
      // get a `TaskCanceled` error (instead of waiting forever). If he never
      // asked for result (1) we will not throw `TaskCanceled` anywhere - we
      // will cancel the task without an error. In rare case (2b) - when he
      // asked for future result, and stored it somewhere without awaiting...
      // He we probably get an unhandled `TaskCanceled`. To avoid this he
      // can just avoid canceling tasks, or storing their future results...

      if (this._completer != null) {
        assert(!_completer!.isCompleted);
        this._completer!.completeError(e, stacktrace);
      } else {
        assert(_completer == null);
        rethrow;
      }
    } finally {
      this._willRun = false; // todo unit test
    }
  }

  /// this completer is only initialized if user asks for [result] future before
  /// we have the result. If the user did not ask for result, no one is waiting
  /// for the result, so we can safely cancel the task without [completeError]
  Completer<R>? _completer;

  /// when the task completes, it initializes sets the following two field. If
  /// the user reads [result] property after that, we will just return the value
  /// instead messing with Completer
  bool _haveResult = false;
  late R _readyResult;

  @override
  Future<R> get result => _haveResult
      ? Future<R>.value(_readyResult)
      : (this._completer ??= Completer<R>()).future;

  bool _willRun = true;

  @override
  bool get willRun => _willRun;

  @override
  set willRun(final bool value) {
    if (this._willRun == value) {
      return;
    }

    if (value) {
      throw StateError(
          'Cannot set willRun to true after it after it has been set to false');
    }

    assert(this._willRun);
    assert(!value);

    this._willRun = false;
    this.onCancel?.call(this);

    if (this._completer?.isCompleted == false) {
      this._completer!.completeError(TaskCanceled);
    }
  }
}

class PriorityTask<R> extends InternalTask<R>
    implements Comparable<PriorityTask<R>> {
  static Unlimited _idGenerator = Unlimited();

  PriorityTask(super.callback, this.priority,
      {super.onCancel});

  final int priority;
  final id = (PriorityTask._idGenerator = PriorityTask._idGenerator.next());

  @override
  int compareTo(final PriorityTask<R> other) {
    // taskA<taskB if taskA has larger priority
    var x = -this.priority.compareTo(other.priority);

    // taskA<taskB if taskA created earlier (so taskA.id<taskB.id)
    if (x == 0) {
      x = this.id.compareTo(other.id);
    }

    return x;
  }
}

@internal
extension QueueExt on PriorityQueue<InternalTask<dynamic>> {
  /// Will throw if the task in not in queue.
  void removeOrThrow(final InternalTask<dynamic> task) {
    final s = this.length;
    if (!this.remove(task)) {
      throw ArgumentError('Task not found.');
    }
    assert(this.length == s - 1);
  }
}

abstract class PriorityScheduler {
  Task<R> run<R>(final GetterFunc<R> callback, [final int priority = 0]);

  int get queueLength;
}
