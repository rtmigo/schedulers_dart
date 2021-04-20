// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'package:meta/meta.dart';

import '10_unlimited.dart';

typedef CancelFunc<T> = void Function(Task<T>);
typedef GetterFunc<T> = T Function();

class TaskCanceled {}

class Task<T> {
  Task(this._callback, {this.onCancel});

  final GetterFunc<T> _callback;
  
  /// Called when used [cancel]s the task. It helps the scheduler to remove the task from 
  /// the queue, if needed. 
  @internal
  final CancelFunc? onCancel;

  @internal
  void runIfNotCanceled() {
    if (!this._canceled) {
      try {
        this._readyResult = this._callback();
        this._haveResult = true;
        this._completer?.complete(this._readyResult);
      }
      catch (e, stacktrace) {
        if (this._completer!=null) {
          this._completer!.completeError(e, stacktrace);
        } else {
          rethrow;
        }
      }
    }
  }

  /// If the user asked for [result], this method will complete the future with [TaskCanceled]
  /// error. If the used did not ask for [result], or the method called for the completed task,
  /// method does nothing.
  @internal
  void completeCanceled() {
    if (this._completer!=null && !this._completer!.isCompleted) {
      this._completer!.completeError(TaskCanceled);
    }
  }

  // this completer is only initialized if user asks for [result] future before 
  // we have the result. If the user did not ask for result, no one is waiting for the result,
  // so we can safely cancel the task without [completeError]
  Completer<T>? _completer;

  // when the task completes, it initializes sets the following two field. If the user reads
  // [result] property after that, we will just return the value instead messing with Completer
  bool _haveResult = false;
  late T _readyResult;

  Future<T> get result => _haveResult ? Future<T>.value(_readyResult) : (this._completer??=Completer<T>()).future;

  void cancel() {
    this._canceled = true;
    this.onCancel?.call(this);
    this.completeCanceled();
  }
  bool _canceled = false;
}

class PriorityTask<T> extends Task<T> implements Comparable {
  static Unlimited _idgen = Unlimited();

  PriorityTask(GetterFunc<T> callback, this.priority, {onCancel}): super(callback, onCancel: onCancel);

  final int priority;
  final id = (PriorityTask._idgen=PriorityTask._idgen.next());

  @override
  int compareTo(other)
  {
    // taskA<taskB if taskA has larger priority
    var x = -this.priority.compareTo(other.priority);

    // taskA<taskB if taskA created earlier (so taskA.id<taskB.id)
    if (x==0) {
      x = this.id.compareTo(other.id);
    }

    return x;
  }
}

abstract class PriorityScheduler {
  PriorityTask<T> run<T>(GetterFunc<T> callback, [int priority = 0]);
  int get queueLength;
}