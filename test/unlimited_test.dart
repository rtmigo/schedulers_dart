// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:schedulers/src/a_unlimited.dart';
import 'package:test/test.dart';

void main() {
  test('CompareTo', () {
    final a = Unlimited();
    final b = Unlimited();

    expect(a.compareTo(b), 0);
    expect(b.compareTo(a), 0);

    final aplus = a.next();

    expect(aplus.compareTo(a), 1);
    expect(a.compareTo(aplus), -1);

    expect(aplus.compareTo(b), 1);
    expect(aplus.compareTo(b.next()), 0);
  });

  test('Operators', () {
    final a = Unlimited();
    final b = Unlimited();

    expect(a == b, true);
    expect(b == a, true);

    expect(a <= b, true);
    expect(b <= a, true);

    final a1 = a.next();
    final b1 = a.next();

    expect(a1 > a, true);
    expect(a > a1, false);

    expect(b1 > b, true);
    expect(b > b1, false);

    expect(a1 == b1, true);
    expect(a1 != b1, false);

    expect(b1 > a, true);
    expect(a > b1, false);
  });

  test('Really Big 1', () {
    var x = Unlimited.fromParts([Unlimited.partMax - 5]);

    expect(x.partsLength, 1);

    for (int i = 0; i < 10; ++i) {
      final n = x.next();
      expect(n > x, true);
      expect(n >= x, true);
      x = n;
    }

    expect(x.partsLength, 2);
  });

  test('Really Big 2', () {
    var x = Unlimited.fromParts([Unlimited.partMax - 5, Unlimited.partMax]);

    expect(x.partsLength, 2);

    for (int i = 0; i < 10; ++i) {
      final n = x.next();
      expect(n > x, true);
      expect(n >= x, true);
      x = n;
    }

    expect(x.partsLength, 3);
  });

  test('Big Strings', () {
    var x = Unlimited.fromParts([Unlimited.partMax - 5, Unlimited.partMax]);

    final strings = <String>[];

    for (int i = 0; i < 10; ++i) {
      final n = x.next();
      x = n;
      strings.add(x.toString());
    }

    expect(strings, [
      'fffffffffffffffffffffffb',
      'fffffffffffffffffffffffc',
      'fffffffffffffffffffffffd',
      'fffffffffffffffffffffffe',
      'ffffffffffffffffffffffff',
      '1000000000000000000000000',
      '1000000000000000000000001',
      '1000000000000000000000002',
      '1000000000000000000000003',
      '1000000000000000000000004'
    ]);
  });

  test('Small strings', () {
    var x = Unlimited();

    expect(x.toString(), '0');
    x = x.next();
    expect(x.toString(), '1');
    x = x.next();
    expect(x.toString(), '2');

    for (var i = 0; i < 200; ++i) {
      x = x.next();
    }

    expect(x.toString(), 'ca');
  });

  test('Hash strings', () {
    final a = Unlimited();
    final b = Unlimited();

    final a1 = a.next();

    expect(a.hashCode, b.hashCode);
    expect(a1.hashCode, isNot(a.hashCode));

    final big = Unlimited.fromParts([Unlimited.partMax - 5, Unlimited.partMax]);
    expect(big.hashCode, big.hashCode);
    expect(big.hashCode, isNot(big.next().hashCode));
  });
}
