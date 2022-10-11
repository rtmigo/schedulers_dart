Dart library for running asynchronous functions on time. Useful for 
load balancing, rate limiting, lazy execution.

*In the examples below, all the `run` calls are performed right 
after object creation. In fact all the schedulers can handle 
`run`s at random moments.*

# IntervalScheduler

Runs tasks asynchronously, maintaining a fixed time interval between starts.

``` dart
final scheduler = IntervalScheduler(delay: Duration(seconds: 1));

scheduler.run(()=>download('pageA')); // starts download immediately
scheduler.run(()=>download('pageB')); // will start one second later
scheduler.run(()=>download('pageC')); // will start two seconds later
```

# RateScheduler

Runs no more than N tasks in a certain period of time.

``` dart
final scheduler = RateScheduler(3, Duration(seconds: 1)); // 3 per second

// the following tasks are executed immediately
scheduler.run(()=>download('pageA'));
scheduler.run(()=>download('pageB'));
scheduler.run(()=>download('pageC'));

// the following tasks are executed one second later
scheduler.run(()=>download('pageD'));
scheduler.run(()=>download('pageE'));
scheduler.run(()=>download('pageF'));
 
// the following tasks are executed two seconds later
scheduler.run(()=>download('pageG'));
scheduler.run(()=>download('pageH'));
scheduler.run(()=>download('pageI'));
```

# ParallelScheduler

Limits the number of tasks running at the same time. This is somewhat similar to
using a thread pool or process pool. But it just runs 
`async` functions.

```dart
// we will run a maximum of three tasks at the same time
final scheduler = ParallelScheduler(3); 

scheduler.run(()=>asyncDownload('pageA')); // executed immediately
scheduler.run(()=>asyncDownload('pageB')); // executed immediately
scheduler.run(()=>asyncDownload('pageC')); // executed immediately

scheduler.run(()=>asyncDownload('pageD'));
// task for pageD will execute when some of the previous tasks finish 
```

# TimeScheduler

Runs tasks asynchronously at the specified time.

```dart
final scheduler = TimeScheduler();

// run the function on January 1st at 17:75
scheduler.run(() { ... }, DateTime(2020, 1, 1, 17, 45));
```

# LazyScheduler

Runs only the last added task and only if no new tasks have been added during 
the time interval.

``` dart
final scheduler = LazyScheduler(latency: Duration(seconds: 1));

scheduler.run(()=>pushUpdate('1')); // maybe we will push 1
scheduler.run(()=>pushUpdate('1+1')); // no we will push 1+1
scheduler.run(()=>pushUpdate('1+1-1')); // no we will push 1+1-1
scheduler.run(()=>pushUpdate('1')); // it's good we're so lazy
scheduler.run(()=>pushUpdate('777')); // maybe we will push this
```

And one second later the `scheduler` runs `pushUpdate('777')`. Other tasks 
are ignored.

We can continue with the same scheduler:

``` dart
scheduler.run(()=>pushUpdate('13')); // we pushed 777, now we maybe push 13
scheduler.run(()=>pushUpdate('10')); // no, we will not push 13...
```

# Awaiting results

Each of the schedulers allows you to wait for the result of the function 
as a regular `Future`. You just have to `await` for the `.result`.

```dart
final a = await download('pageA');
final b = await scheduler.run(()=>download('pageB')).result;
```

These two calls to the `download` function behave in much the same way. The only
difference is that the scheduler can delay the execution of the function for
suitable times.

# License

Copyright © 2021 [Artsiom iG](https://github.com/rtmigo).
Released under the [MIT License](LICENSE).
