// SPDX-FileCopyrightText: (c) 2021 Artsiom iG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:core';

import 'package:schedulers/src/b_base.dart';
import 'package:test/test.dart';

void main() {
  test('compare by ids', () async {
    final a = PriorityTask(() {}, 5);
    final b = PriorityTask(() {}, 5);
    expect(a.compareTo(b), -1);
    expect(b.compareTo(a), 1);
  });

  test('compare by priorities', () async {
    final a = PriorityTask(() {}, 5);
    final b = PriorityTask(() {}, 7);
    expect(a.compareTo(b), 1);
    expect(b.compareTo(a), -1);
  });
}
