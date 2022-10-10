// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:core';
import 'package:schedulers/src/c_interval.dart';
import 'package:test/test.dart';

void main() {

	// todo test tasks that throw exceptions
	// todo test waiting for failed tasks
	// todo test waiting for tasks when the scheduler is disposed

	test('IntervalScheduler', () async {
		for (var i=0; i<10; ++i)
		{
			var stq = IntervalScheduler(delay: Duration(milliseconds: 1000%30));

			String txt = '';

			stq.run(() {txt+='.';}, 1);
			stq.run(() {txt+='X';}, 100);
			stq.run(() {txt+='A';}, 200);
			stq.run(() {txt+='Y';}, 100);
			var oopsTask = stq.run(() {txt+='oops';}, 100);
			stq.run(() {txt+='B';}, 200);
			stq.run(() {txt+='.';}, 2);
			stq.run(() {txt+='Z';}, 100);
			stq.run(() {txt+='.';}, 3);

			oopsTask.willRun = false;

			await stq.completed;

			expect(txt, 'ABXYZ...');
		}
	});

	test('IntervalScheduler dispose', () async {
		var stq = IntervalScheduler(delay: Duration(milliseconds: 100));
		int x = 0;
		for (var i=0; i<10; ++i) {
			stq.run(() {x++;});
		}

		Future.delayed(Duration(milliseconds: 330), () {stq.dispose();});

		await Future.delayed(Duration(milliseconds: 600));

		expect(x, 3);
	});

}