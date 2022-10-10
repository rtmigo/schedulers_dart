// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'b_base.dart';

class TimeScheduler
{
  Task<R> run<R>(final GetterFunc<R> func, final DateTime time) {

    if (this._disposed) {
      throw StateError('The object is disposed');
    }

    final t = InternalTask<R>(func);
    Future.delayed(_computeDelay(time), () {
      if (!this._disposed) {
        t.runIfNotCanceled();
      }
    });

    return t;
  }

  void dispose() {
    // todo cancel tasks
    this._disposed = true;
  }

  bool _disposed = false;


  Duration _computeDelay(final DateTime targetTime, {DateTime? now})
  {
    now ??= DateTime.now();

    if (targetTime.isBefore(now)) {
      return const Duration(microseconds: 0);
    } else {
      final result = targetTime.difference(now);
      assert(!result.isNegative);
      return result;
    }
  }
}
