// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

/// Unlimited numeric value that can be increased an infinite number of times.
/// Useful for creating identifiers that are unique in the course of the
/// program, and each subsequent one is larger than the previous one.
class Unlimited implements Comparable<Unlimited> {
  // Looks like I invented the wheel. Instead of this object, we could use a
  // regular BigInt. I still keeping it, because it's tested and not a fact that
  // BigInt is more effective for the specific task.

  Unlimited() : _parts = <int>[0];

  @visibleForTesting
  @internal
  Unlimited.fromParts(this._parts);

  @internal
  static const partMax = 0xFFFFFFFFFFFF;

  final List<int> _parts;

  @internal
  int get partsLength => _parts.length;

  Unlimited next() {
    final newParts = List<int>.from(_parts);

    for (int i = 0;; ++i) {
      if (newParts.length <= i) {
        newParts.add(1);
        break;
      }
      if (newParts[i] < partMax) {
        newParts[i]++;
        break;
      } else {
        assert(newParts[i] == partMax);
        newParts[i] = 0;
        // and go to next i: increment higher part
      }
    }

    final result = Unlimited.fromParts(newParts);

    assert(result > this);
    assert(result >= this);
    assert(this < result);
    assert(this <= result);
    assert(this.compareTo(result) == -1);
    assert(result.compareTo(this) == 1);

    return result;
  }

  @override
  int compareTo(final Unlimited other) {
    if (this._parts.length != other._parts.length) {
      return (this._parts.length < other._parts.length) ? -1 : 1;
    }

    for (int i = this._parts.length - 1; i >= 0; --i) {
      if (this._parts[i] != other._parts[i]) {
        return (this._parts[i] < other._parts[i]) ? -1 : 1;
      }
    }

    return 0;
  }

  @override
  bool operator ==(final Object other) =>
      (other is Unlimited) && this.compareTo(other) == 0;
  bool operator <(final Object other) =>
      (other is Unlimited) && this.compareTo(other) < 0;
  bool operator >(final Object other) =>
      (other is Unlimited) && this.compareTo(other) > 0;
  bool operator <=(final Object other) =>
      (other is Unlimited) && this.compareTo(other) <= 0;
  bool operator >=(final Object other) =>
      (other is Unlimited) && this.compareTo(other) >= 0;

  @override
  int get hashCode => this._parts.first;

  @override
  String toString() {
    String result = '';

    for (int i = 0; i < this._parts.length; ++i) {
      var hex = this._parts[i].toRadixString(16);
      if (i < this._parts.length - 1) {
        hex = hex.padLeft(12, '0');
      }
      result = hex + result;
    }

    return result;
  }
}
