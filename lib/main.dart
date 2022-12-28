import 'package:intellij_project/page_activities.dart';
import 'package:intellij_project/page_intervals.dart';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TimeTracker',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.blueGrey[50],
        primarySwatch: Colors.blueGrey,
        textTheme: const TextTheme(
            subtitle1: TextStyle(fontSize:20.0),
            bodyText2:TextStyle(fontSize:20.0)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          subtitle1: TextStyle(fontSize:20.0),
          bodyText2:TextStyle(fontSize:20.0)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey
        ),
      ),
        home: PageActivities(0)
    );
  }
}