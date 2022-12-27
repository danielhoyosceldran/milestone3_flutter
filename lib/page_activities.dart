import 'package:intellij_project/tree.dart';
import 'package:intellij_project/PageIntervals.dart';
import 'package:flutter/material.dart';
import 'package:intellij_project/tree.dart' hide getTree;
// the old getTree()
import 'package:intellij_project/requests.dart' as requests;
// has the new getTree() that sends an http request to the server
import 'dart:async';

class PageActivities extends StatefulWidget {
  int id;

  PageActivities(this.id);

  @override
  _PageActivitiesState createState() => _PageActivitiesState();
}

class _PageActivitiesState extends State<PageActivities> {
  late Tree tree;

  late int id;
  late Future<Tree> futureTree;

  late Timer _timer;
  static const int periodeRefresh = 6;

  void _activateTimer() {
    _timer = Timer.periodic(Duration(seconds: periodeRefresh), (Timer t) {
      futureTree = requests.getTree(id);
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    id = widget.id; // of PageActivities
    futureTree = requests.getTree(id);
  }

  void _navigateDownActivities(int childId) {
    // we can not do just _refresh() because then the up arrow doesnt appear in the appbar
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      builder: (context) => PageActivities(childId),
    )).then( (var value) {
      _refresh();
    });
  }

  void _navigateDownIntervals(int childId) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      builder: (context) => PageIntervals(childId),
    )).then( (var value) {
      _refresh();
    });
    //https://stackoverflow.com/questions/49830553/how-to-go-back-and-refresh-the-previous-page-in-flutter?noredirect=1&lq=1
  }

  Widget _buildRowActionMenu(BuildContext context, int index) {
    if (index == 0) {
      return ListTile(
        title: const Text('Add project'),
        leading: const Icon(Icons.add),
        iconColor: Colors.blueGrey,
        onTap: () => {},
      );
    }
    return ListTile(
      title: const Text('Add task'),
      leading: const Icon(Icons.add),
      iconColor: Colors.blueGrey,
      onTap: () => {},
    );
  }

  void _addActivity(){
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return ListView.separated(
            itemBuilder: (BuildContext context, int index) => _buildRowActionMenu(context, index),
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemCount: 2
        );
      },
    );
  }

  Widget _buildRow(Activity activity, int index) {
    String strDuration = Duration(seconds: activity.duration).toString().split('.').first;
    // split by '.' and taking first element of resulting list removes the microseconds part
    if (activity is Project) {
      return ListTile(
        title: Text('${activity.name}'),
        trailing: Text('$strDuration'),
        onTap: () => _navigateDownActivities(activity.id),
      );
    } else if (activity is Task) {
      Task task = activity as Task;
      // at the moment is the same, maybe changes in the future
      Widget trailing;
      trailing = Text('$strDuration');

      return ListTile(
        title: Text('${activity.name}'),
        trailing: trailing,
        onTap: () => _navigateDownIntervals(activity.id),
        onLongPress: () {
          if ((activity as Task).active) {
            requests.stop(activity.id);
            _refresh(); // to show immediately that task has started
          } else {
            requests.start(activity.id);
            _refresh(); // to show immediately that task has stopped
          }
        },
      );
    }
    return ListTile(
      title: Text('filed'),
    );
  }

  void _refresh() async {
    futureTree = requests.getTree(id); // to be used in build()
    setState(() {});
  }

  // future with listview
  // https://medium.com/nonstopio/flutter-future-builder-with-list-view-builder-d7212314e8c9
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tree>(
      future: futureTree,
      // this makes the tree of children, when available, go into snapshot.data
      builder: (context, snapshot) {
        // anonymous function
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(snapshot.data!.root.name), // updated 16-dec-2022
              actions: <Widget>[
                IconButton(icon: Icon(Icons.home),
                    onPressed: () {} // TODO go home page = root
                ),
                //TODO other actions
              ],
            ),
            body: ListView.separated(
              // it's like ListView.builder() but better because it includes a separator between items
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.root.children.length, // updated 16-dec-2022
              itemBuilder: (BuildContext context, int index) =>
                  _buildRow(snapshot.data!.root.children[index], index), // updated 16-dec-2022
              separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
            ),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // By default, show a progress indicator
        return Container(
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(),
            ));
      },
    );
  }
}