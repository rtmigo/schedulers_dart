# schedulers

Objects in this library run callbacks asynchronously, allowing useful pauses 
between calls. This can be used for load balancing, rate limiting, lazy execution.

In the examples below, objects receive tasks immediately after 
constructors. But in fact, objects can handle calls to the `run` method 
at random times. The tasks will be distributed in time in the same way.

# IntervalScheduler

Runs tasks asynchronously, maintaining a fixed time interval between starts.

``` dart
final scheduler = IntervalScheduler(delay: Duration(seconds: 1));

scheduler.run(()=>downloadPage('pageA')); // starts download immediately
scheduler.run(()=>downloadPage('pageB')); // will start one second later
scheduler.run(()=>downloadPage('pageC')); // will start two seconds later
```

# RateScheduler

Runs no more than N tasks in a certain period of time.

``` dart
final scheduler = RateScheduler(3, Duration(seconds: 1)); // 3 per second

// the following tasks are executed immediately
scheduler.run(()=>downloadPage('pageA'));
scheduler.run(()=>downloadPage('pageB'));
scheduler.run(()=>downloadPage('pageC'));

// the following tasks are executed one second later
scheduler.run(()=>downloadPage('pageD'));
scheduler.run(()=>downloadPage('pageE'));
scheduler.run(()=>downloadPage('pageF'));
 
// the following tasks are executed two seconds later
scheduler.run(()=>downloadPage('pageG'));
scheduler.run(()=>downloadPage('pageH'));
scheduler.run(()=>downloadPage('pageI'));
```

# LazyScheduler

Runs only the last added task and only if no new tasks have been added during 
the time interval.

``` dart
final scheduler = LazyScheduler(latency: Duration(seconds: 1));

scheduler.run(()=>pushUpdate('1')); // maybe we will push 1
scheduler.run(()=>pushUpdate('1+1')); // no we will push 1+1
scheduler.run(()=>pushUpdate('1+1-1')); // no we will push 1+1-1
scheduler.run(()=>pushUpdate('1')); // it's good we so lazy
scheduler.run(()=>pushUpdate('777')); // maybe we will push this
```

And one second later the `scheduler` runs `pushUpdate('777')`. Other tasks 
are ignored.

We can continue with the same scheduler:

``` dart
scheduler.run(()=>pushUpdate('13')); // we pushed 777, now we maybe push 13
scheduler.run(()=>pushUpdate('10')); // no, we will not push 13...
```


