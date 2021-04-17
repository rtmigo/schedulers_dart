# schedulers

Objects in this library run callbacks asynchronously, allowing useful pauses 
between calls. This can be used for load balancing, rate limiting, lazy execution.

# IntervalScheduler

Runs tasks asynchronously, maintaining a fixed time interval between starts.

``` dart
final scheduler = IntervalScheduler(delay: Duration(seconds: 1));

scheduler.run(()=>downloadPage('page1')); // downloads immediately
scheduler.run(()=>downloadPage('page2')); // downloads one second later
scheduler.run(()=>downloadPage('page3')); // downloads two seconds later
```

# LazyScheduler

Runs only the last added task and only if no new tasks have been added during 
the time interval.

``` dart
final scheduler = LazyScheduler(delay: Duration(seconds: 1));

scheduler.run(()=>pushUpdate('1')); // maybe we will push 1
scheduler.run(()=>pushUpdate('1+1')); // no we will push 1+1
scheduler.run(()=>pushUpdate('1+1-1')); // no we will push 1+1-1
scheduler.run(()=>pushUpdate('1')); // it's good we so lazy
scheduler.run(()=>pushUpdate('777')); // maybe we will push this
```

And one second later the `scheduler` runs `pushUpdate('777')`.  

