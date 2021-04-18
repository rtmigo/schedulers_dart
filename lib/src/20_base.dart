// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'package:meta/meta.dart';

import '10_unlimited.dart';

typedef CancelFunc<T> = void Function(Task<T>);
typedef GetterFunc<T> = T Function();


class Task<T> {
  Task(this._callback, {this.onCancel});

  final GetterFunc<T> _callback;
  final CancelFunc? onCancel;

  @internal
  void runIfNotCanceled() {
    if (!this._canceled) {
      try {
        this._completer.complete(this._callback());
      }
      catch (e, stacktrace) {
        this._completer.completeError(e, stacktrace);
      }
    }
  }

  final Completer<T> _completer = Completer<T>();

  Future<T> get result => this._completer.future;

  void cancel() {
    this._canceled = true;
    this.onCancel?.call(this);
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