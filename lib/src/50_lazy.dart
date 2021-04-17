// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:schedulers/src/10_unlimited.dart';
import 'package:schedulers/src/20_base.dart';

/// Performs tasks not immediately, but with a delay. If new tasks are added during this delay,
/// all old tasks are canceled.
///
/// That is, if you add many tasks within a short period of time, then only one of them will be
/// executed: the last one added.
class LazyScheduler {
  int _ignored = 0;
  final int? callEach;
  GetterFunc<void>? _callback;
  late Duration latency;

  LazyScheduler({Duration? latency, this.callEach}) {
    this.latency = latency ?? const Duration(milliseconds: 1000);
  }

  Unlimited _newestRunId = Unlimited();

  void run(GetterFunc<void> callback) async {
    this._callback = callback;

    _newestRunId = _newestRunId.next();
    final runId = _newestRunId;

    await Future.delayed(this.latency);

    if (this._newestRunId == runId) {
      this._callback!();
      this._ignored = 0;
    } else if (this.callEach != null && ++this._ignored >= this.callEach!) {
      this._callback!();
      this._ignored = 0;
    }
  }
}
