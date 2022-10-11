// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:schedulers/schedulers.dart';
import 'package:test/test.dart';

void main() {
  // todo test tasks that throw exceptions

  test('lazy 1', () async {

    final scheduler = LazyScheduler(latency: const Duration(milliseconds: 100));

    int x=0;
    int y=0;
    int funcA()=>x++;
    int funcB()=>y++;

    for (int i=0; i<100; ++i) {
      scheduler.run(funcA);
    }

    expect(x, 0);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(x, 0);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(x, 1);

    for (int i=0; i<100; ++i) {
      scheduler.run(funcA);
      scheduler.run(funcB);
    }
    expect(x, 1);
    expect(y, 0);

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(x, 1);
    expect(y, 1);

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(x, 1);
    expect(y, 1);
  });
}
