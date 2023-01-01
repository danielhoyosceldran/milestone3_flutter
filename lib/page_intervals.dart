import 'package:flutter/material.dart';
import 'package:intellij_project/tree.dart' as Tree;

import 'package:intellij_project/tree.dart' as Tree hide getTree;
// to avoid collision with an Interval class in another library
import 'package:intellij_project/requests.dart' as requests;
import 'package:intellij_project/page_activities.dart';
import 'dart:async';

class PageIntervals extends StatefulWidget {
  int id;

  PageIntervals(this.id);
  @override
  _PageIntervalsState createState() => _PageIntervalsState();
}

class _PageIntervalsState extends State<PageIntervals> {
  late Tree.Tree tree;
  late Tree.Interval _interval;

  late int id;
  late Future<Tree.Tree> futureTree;

  late Timer _timer;
  static const int periodeRefresh = 6;

  late bool active;
  final Color _timerActive = Colors.green;
  final Color _timerStop = Colors.red;
  late Color _background;

  // better a multi
  // ple of period in TimeTracker, 2 seconds

  void _activateTimer() {
    _timer = Timer.periodic(const Duration(seconds: periodeRefresh), (Timer t) {
      futureTree = requests.getTree(id);
      setState(() {});
    });
  }

  @override
  void dispose() {
    // "The framework calls this method when this State object will never build again"
    // therefore when going up
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    id = widget.id;
    futureTree = requests.getTree(id);
    _background = _timerActive;

    _activateTimer();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tree.Tree>(
      future: futureTree,
      // this makes the tree of children, when available, go into snapshot.data
      builder: (context, snapshot) {
        // anonymous function
        if (snapshot.hasData) {
          int numChildren = snapshot.data!.root.children.length; // updated 16-dec-2022
          return Scaffold(
            appBar: AppBar(
              title: Text(snapshot.data!.root.name), // updated 16-dec-2022
              actions: <Widget>[
                IconButton(icon: const Icon(Icons.home),
                  onPressed: () {
                    while(Navigator.of(context).canPop()) {
                      //print("pop");
                      Navigator.of(context).pop();
                    }
                    PageActivities(0);
                  }, // TODO
                )
              ],
            ),
            body: ListView.separated(
              // it's like ListView.builder() but better because it includes a separator between items
              padding: const EdgeInsets.all(16.0),
              itemCount: numChildren,
              itemBuilder: (BuildContext context, int index) =>
                  _buildRow(snapshot.data!.root.children[index], index), // updated 16-dec-2022
              separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_background == _timerStop) {
                    _background = _timerActive;
                  }
                  else {
                    _background = _timerStop;
                  }
                });
              },
              backgroundColor: _background,
              child: const Text("stop"),
            ),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // By default, show a progress indicator
        return Container(
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ));
      },
    );
  }
  Widget _buildRow(Tree.Interval interval, int index) {
    String strDuration = Duration(seconds: interval.duration).toString().split('.').first;
    String strInitialDate = interval.initialDate.toString().split('.')[0];
    // this removes the microseconds part
    String strFinalDate = interval.finalDate.toString().split('.')[0];
    return ListTile(
      title: Text('from:  ${strInitialDate} \nto:       ${strFinalDate}'),
      trailing: Text('$strDuration'),
    );
  }
}