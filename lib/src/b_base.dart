// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:meta/meta.dart';

import 'a_unlimited.dart';

typedef CancelFunc<R> = void Function(InternalTask<R>);
typedef GetterFunc<R> = R Function();

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
  InternalTask(this._callback, {this.onCancel});

  final GetterFunc<R> _callback;

  /// Called when used [cancel]s the task. It helps the scheduler to remove the
  /// task from the queue, if needed.
  @internal
  final CancelFunc<R>? onCancel;

  @internal
  void runIfNotCanceled() {
    if (this._willRun) {
      try {
        this._readyResult = this._callback();
        this._haveResult = true;
        this._completer?.complete(this._readyResult);
      } catch (e, stacktrace) {
        if (this._completer != null) {
          this._completer!.completeError(e, stacktrace);
        } else {
          rethrow;
        }
      } finally {
        this._willRun = false; // todo unit test
      }
    }
  }

  // this completer is only initialized if user asks for [result] future before
  // we have the result. If the user did not ask for result, no one is waiting
  // for the result, so we can safely cancel the task without [completeError]
  Completer<R>? _completer;

  // when the task completes, it initializes sets the following two field. If
  // the user reads [result] property after that, we will just return the value
  // instead messing with Completer
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

  PriorityTask(final GetterFunc<R> callback, this.priority,
      {final CancelFunc<R>? onCancel})
      : super(callback, onCancel: onCancel);

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

abstract class PriorityScheduler {
  Task<R> run<R>(final GetterFunc<R> callback, [final int priority = 0]);

  int get queueLength;
}
