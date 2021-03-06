// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:schedulers/schedulers.dart';
import 'package:test/test.dart';

void main() {
  test('lazy 1', () async {

    final scheduler = LazyScheduler(latency: const Duration(milliseconds: 100));

    int x=0;
    int y=0;
    final funcA = ()=>x++;
    final funcB = ()=>y++;

    for (int i=0; i<100; ++i) {
      scheduler.run(funcA);
    }

    expect(x, 0);

    await Future.delayed(const Duration(milliseconds: 10));
    expect(x, 0);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(x, 1);

    for (int i=0; i<100; ++i) {
      scheduler.run(funcA);
      scheduler.run(funcB);
    }
    expect(x, 1);
    expect(y, 0);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(x, 1);
    expect(y, 1);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(x, 1);
    expect(y, 1);
  });
}
