// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:schedulers/schedulers.dart';
import 'package:test/test.dart';

void main() {
  test('Time', () async {

    var now = DateTime.now().toUtc();

    int value = 0;

    var s = TimeScheduler();
    var t1 = s.run(()=>(value=1), now.add(Duration(seconds: 1)));
    var t2 = s.run(()=>(value=2), now.add(Duration(seconds: 2)));
    var t3 = s.run(()=>(value=3), now.add(Duration(seconds: 3)));
    var t4 = s.run(()=>(value=4), now.add(Duration(seconds: 4)));

    expect(value, 0);
    await Future.delayed(Duration(milliseconds: 1100));
    expect(value, 1);
    await Future.delayed(Duration(milliseconds: 1100));
    expect(value, 2);
    t3.cancel();
    await Future.delayed(Duration(milliseconds: 1100));
    expect(value, 2);
    s.dispose();
    await Future.delayed(Duration(milliseconds: 1100));
    expect(value, 2);
  });

  test('Cannot add to disposed', () async {
    var s = TimeScheduler();
    s.run(() => {}, DateTime.now().add(Duration(seconds: 1)));
    s.dispose();
    expect(()=>s.run(() => {}, DateTime.now().add(Duration(seconds: 1))), throwsStateError);
  });

}
