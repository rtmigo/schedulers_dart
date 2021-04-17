// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:core';
import 'package:schedulers/src/50_interval.dart';
import 'package:test/test.dart';


void main()
{


	test('IntervalScheduler', () async
	{
		for (var i=0; i<10; ++i)
		{
			var stq = IntervalScheduler();

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

			stq.cancel(oopsTask);

			await stq.completed;

			expect(txt, 'ABXYZ...');
		}
	});

}