// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import '10_unlimited.dart';


class BaseTask implements Comparable
{
  static Unlimited _idgen = Unlimited();

  BaseTask(this.priority);

  final int priority;
  final id = (BaseTask._idgen=BaseTask._idgen.next());

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

typedef GetterFunc<T> = T Function();

class Task<T> extends BaseTask
{
  Task(this.callback, priority): super(priority);

  final GetterFunc<T> callback;

  Completer<T> completer = Completer<T>();

  Future<T> get result => this.completer.future;
}

abstract class PriorityScheduler {
  Task<T> run<T>(GetterFunc<T> callback, [int priority = 0]);

  void cancel(Task t);

  int get queueLength;
}