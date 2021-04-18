// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:async';
import '20_base.dart';

class TimeScheduler
{
  Task run<T>(GetterFunc<T> func, DateTime time) {

    if (this._disposed) {
      throw StateError('The object is disposed');
    }

    var t = Task<T>(func);
    Future.delayed(_computeDelay(time), () {
      if (!this._disposed) {
        t.runIfNotCanceled();
      }
    });

    return t;
  }

  void dispose() {
    this._disposed = true;
  }

  bool _disposed = false;


  Duration _computeDelay(DateTime targetTime, {DateTime? now})
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
