// SPDX-FileCopyrightText: (c) 2021 Artsiom iG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:schedulers/schedulers.dart';
import 'package:test/test.dart';

void main() {

  // todo test tasks that throw exceptions
  // todo test waiting for failed tasks
  // todo test waiting for tasks when the scheduler is disposed


  test('RateLimitingScheduler Limiting', () async {
    const F = 2;
    final scheduler = RateScheduler(3, const Duration(milliseconds: 100 * F));

    int a = 0;

    void taskA() {
      a++;
    }

    for (var i = 0; i < 10; ++i) {
      scheduler.run(taskA);
    }

    expect(a, 0);

    // we run three tasks immediately. Half interval passed, but they are all completed
    await Future<void>.delayed(Duration(milliseconds: 50 * F));
    expect(a, 3);

    await Future<void>.delayed(Duration(milliseconds: 100 * F));
    expect(a, 6);

    await Future<void>.delayed(Duration(milliseconds: 100 * F));
    expect(a, 9);

    await Future<void>.delayed(Duration(milliseconds: 100 * F));
    expect(a, 10);
  });

  test('RateLimitingScheduler Different Tasks', () async {
    const F = 1;
    final scheduler = RateScheduler(5, Duration(milliseconds: 100 * F));

    int a = 0;
    int b = 0;
    int c = 0;

    void taskA() {
      a++;
    }

    void taskB() {
      b++;
    }

    void taskC() {
      c++;
    }

    final List<void Function()> tasks = [];
    for (int i = 0; i < 4; ++i) {
      tasks.add(taskA);
    }
    for (int i = 0; i < 3; ++i) {
      tasks.add(taskB);
    }
    for (int i = 0; i < 6; ++i) {
      tasks.add(taskC);
    }

    tasks.shuffle();

    for (final t in tasks) {
      scheduler.run(t);
    }

    await Future<void>.delayed(Duration(milliseconds: 500 * F));

    expect(a, 4);
    expect(b, 3);
    expect(c, 6);
  });

  test('RateLimitingScheduler Future', () async {
    final scheduler = RateScheduler(5, Duration(milliseconds: 100));

    int a = 0;
    int funcOk() {
      return ++a;
    }

    int funcOops() {
      throw Exception('Oops');
    }

    final task1 = scheduler.run(funcOk);
    final taskZ = scheduler.run(funcOops);
    final task2 = scheduler.run(funcOk);

    expect(() async => taskZ.result, throwsException);
    expect(await task2.result, 2);
    expect(await task1.result, 1);
  });
}
