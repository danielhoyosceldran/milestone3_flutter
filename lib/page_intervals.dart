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

  late bool _builderInitState;

  late int id;
  late Future<Tree.Tree> futureTree;

  late Timer _timer;
  static const int periodeRefresh = 1;

  late String _activeText;
  late bool _active;
  late bool _activeToggleButton;
  final Color _timerActiveGreen = Colors.green;
  final Color _timerStopRed = Colors.red;
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
    _builderInitState = true;

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

          // only executes first time builder's called
          if (_builderInitState) {
            if(snapshot.data!.root.active) {
              _active = true;
              _activeText = "Stop";
              _background = _timerStopRed;
            } else {
              _active = false;
              _activeText = "Start";
              _background = _timerActiveGreen;
            }
            _builderInitState = false;
          }

          // executed every all the time
          if (snapshot.data!.root.children.isNotEmpty) { // Hi ha intervals
            int size = snapshot.data!.root.children.length;
            Tree.Interval interval = snapshot.data!.root.children[size - 1];

            if ((interval.duration < 2) && _active) {
              _activeToggleButton = false;
            } else {
              _activeToggleButton = true;
            }
          } else { // No hi ha cap interval
            _activeToggleButton = true;
          }

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
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _activeToggleButton
              ? () {
                if (_background == _timerStopRed) { // active == true
                  _active = false;
                  _activeText = "Start";
                  _background = _timerActiveGreen;
                  requests.stop(widget.id);
                } else if (_background == _timerActiveGreen){
                  _active = true;
                  _activeText = "Stop";
                  _background = _timerStopRed;
                  requests.start(widget.id);
                }
              }
              : null,
              backgroundColor: _background,
              label: Text(_activeText),
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
    late Icon activeIcon;
    if (interval.active) {
      activeIcon = const Icon(Icons.play_arrow_outlined, color: Colors.green);
    } else {
      activeIcon = const Icon(Icons.pause_circle_outline_outlined, color: Colors.black54);
    }
    // this removes the microseconds part
    String strFinalDate = interval.finalDate.toString().split('.')[0];
    return ListTile(
      title: Text('from:  $strInitialDate \nto:       $strFinalDate'),
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("$strDuration  ", textAlign: TextAlign.right),
          const SizedBox(width: 10),
          activeIcon
        ],
      ),
    );
  }
}