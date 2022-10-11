import 'dart:async';
import 'dart:math';

import 'package:schedulers/src/b_base.dart';
import 'package:schedulers/src/c_concurrent.dart';
import 'package:test/test.dart';

//import '../bin/source/pool.dart';

class OmgError extends StateError {
  OmgError(int x) : super(x.toString());
}

void waitOrCrash(final Iterable<Future<dynamic>> items) {}

void main() {


  test("one", () async {
    final r = Random();
    final pool = ParallelScheduler(concurrency: 4);
    final futures = List<Task<int>>.empty(growable: true);
    int maxEver = 0;
    for (int i = 0; i < 100; ++i) {
      final t = pool.run(() async {
        expect(pool.currentlyRunning, lessThanOrEqualTo(4));
        maxEver = max(maxEver, pool.currentlyRunning);
        await Future<void>.delayed(Duration(milliseconds: r.nextInt(50)));
        //sleep(Duration(milliseconds: r.nextInt(50)));

        if (i % 4 == 0) {
          throw OmgError(i);
        }

        expect(pool.currentlyRunning, lessThanOrEqualTo(4));
        maxEver = max(maxEver, pool.currentlyRunning);
        return 3;
      });
      futures.add(t);
      //unawaited(t.result.whenComplete(() => 0));
      unawaited(Future.microtask(() async {
        try {
          await t.result;
        } catch (_) {}
      }));
    }

    int success = 0;
    int errors = 0;

    for (final r in futures) {
      try {
        await r.result;
        success++;
      } on OmgError catch (_) {
        errors++;
      }
    }

    //await Future.delayed(Duration(seconds: 5));

    expect(errors, 25);
    expect(success, 75);
    expect(pool.currentlyRunning, 0);
  });

  group("Unhandled exceptions", () {
    test("exception from block is thrown to the zone", () async {
      bool gotError = false;
      await runZonedGuarded(() async {
        final pool = ParallelScheduler(concurrency: 4);
        pool.run(() => throw "Oops!");
        await Future<void>.delayed(Duration(milliseconds: 100));
      }, (_, __) => gotError = true);
      expect(gotError, true);
    });

    test("the same without exception", () async {
      bool gotError = false;
      await runZonedGuarded(() async {
        final pool = ParallelScheduler(concurrency: 4);
        pool.run(() => 1);
        await Future<void>.delayed(Duration(milliseconds: 100));
      }, (_, __) => gotError = true);
      expect(gotError, false);
    });
  });

  test("million tasks", () async {
    // test whether too many tasks can lead to stack overflow
    final pool = ParallelScheduler(concurrency: 32);
    final futures = List<Future<int>>.empty(growable: true);
    for (int i = 0; i < 1000000; ++i) {
      futures.add(pool.run(() async => i).result);
    }
    final results = await Future.wait(futures);

    expect(results.fold(0, (final sum, final x) => sum + x), 499999500000);
  });
}
