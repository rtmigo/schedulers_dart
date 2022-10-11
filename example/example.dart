import 'package:schedulers/schedulers.dart';

Future<void> download(String url) async {
  // relax, this is an example
}

void main() {
  final scheduler = RateScheduler(3, Duration(seconds: 1)); // 3 per second

  // the following tasks are executed immediately
  scheduler.run(() => download('pageA'));
  scheduler.run(() => download('pageB'));
  scheduler.run(() => download('pageC'));

  // the following tasks are executed one second later
  scheduler.run(() => download('pageD'));
  scheduler.run(() => download('pageE'));
  scheduler.run(() => download('pageF'));

  // the following tasks are executed two seconds later
  scheduler.run(() => download('pageG'));
  scheduler.run(() => download('pageH'));
  scheduler.run(() => download('pageI'));
}
