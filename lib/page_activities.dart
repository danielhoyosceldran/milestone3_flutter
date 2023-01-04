import 'package:intellij_project/tree.dart';
import 'package:intellij_project/page_intervals.dart';
import 'package:flutter/material.dart';
import 'package:intellij_project/tree.dart' hide getTree;
// the old getTree()
import 'package:intellij_project/requests.dart' as requests;
// has the new getTree() that sends an http request to the server
import 'dart:async';

enum NewActivitySendMode { project, task }

class PageActivities extends StatefulWidget {
  int id;

  PageActivities(this.id);

  @override
  _PageActivitiesState createState() => _PageActivitiesState();
}

class _PageActivitiesState extends State<PageActivities> {
  late Tree tree;
  final _activityNameController = TextEditingController();
  final _searchByTagController = TextEditingController();
  late int id; // Ha de ser late? Al tutorial no ho fica
  late Future<Tree> futureTree; // idem
  late bool _active;

  late Timer _timer;
  static const int periodeRefresh = 6;
  // better a multiple of period in TimeTracker, 2 seconds

  void _activateTimer() {
    _timer = Timer.periodic(Duration(seconds: periodeRefresh), (Timer t) {
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
    super.initState();

    id = widget.id; // of PageActivities
    futureTree = requests.getTree(id);
    _activateTimer();
  }

  void _navigateDownActivities(int childId) {
    _timer.cancel();
    // we can not do just _refresh() because then the up arrow doesnt appear in the appbar
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      builder: (context) => PageActivities(childId),
    )).then( (var value) {
      _activateTimer();
      _refresh();
    });
    //https://stackoverflow.com/questions/49830553/how-to-go-back-and-refresh-the-previous-page-in-flutter?noredirect=1&lq=1
  }

  void _navigateDownIntervals(int childId) {
    _timer.cancel();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
      builder: (context) => PageIntervals(childId),
    )).then( (var value) {
      _activateTimer();
      _refresh();
    });
  }

  OutlinedButton confirmNameButton(BuildContext context, NewActivitySendMode nasm) {
    return OutlinedButton(
      onPressed: () {
        if (nasm == NewActivitySendMode.project) {
          requests.newProject(widget.id, _activityNameController.text);
        } else if (nasm == NewActivitySendMode.task) {
          requests.newTask(widget.id, _activityNameController.text);
        }
        Navigator.of(context).pop();
        _activityNameController.text = "";
      },
      child: const Text("Add"),
    );
  }

  OutlinedButton searchBTButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {

      },
      child: const Text("Search"),
    );
  }

  SimpleDialog newActivityAction(NewActivitySendMode activityType, String title) {
    return SimpleDialog(
      title: Text("${title}"),
      children: <Widget>[
        TextFormField(
          controller: _activityNameController, // ${_projectNameController.text} is what we need to get the projectName
          textInputAction: TextInputAction.go,
        ),
        confirmNameButton(context, NewActivitySendMode.project),
      ],
    );
  }

  Widget _buildRowActionMenu(BuildContext context, int index) {
    late String buttonText;
    late String dialogTitle;
    late NewActivitySendMode activityType;

    if (index == 0) {
      buttonText = "Add project";
      dialogTitle = "Project name";
      activityType = NewActivitySendMode.project;
    } else if (index == 1) {
      buttonText = "Add task";
      dialogTitle = "Task name";
      activityType = NewActivitySendMode.task;
    } else {
      throw Exception('Index error on add activity button');
    }

    return ListTile(
      title: Text('${buttonText}'),
      leading: const Icon(Icons.add),
      iconColor: Colors.blueGrey,
      onTap: () => {
        showDialog(context: context, builder: (BuildContext context) {
          return newActivityAction(activityType, "${dialogTitle}");
        })
      },
    );
  }

  void _addActivity(){
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 130,
          child: ListView.separated(
              itemBuilder: (BuildContext context, int index) => _buildRowActionMenu(context, index),
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemCount: 2
          ),
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
        leading: const Icon(Icons.folder),
        iconColor: Colors.blueGrey,
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
    return const ListTile(
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
              title: Text("Time Tracker: ${snapshot.data!.root.name}"),//Text(snapshot.data!.root.name), // updated 16-dec-2022
              actions: <Widget>[
                IconButton(icon: const Icon(Icons.search),
                    onPressed: () {
                        print("Search by tag");
                        showDialog(context: context, builder: (BuildContext context) {
                          return SimpleDialog(
                            title: const Text("Seach by tag"),
                            children: <Widget>[
                              TextFormField(
                                controller: _searchByTagController, // ${_searchByTagController.text} is what we need to get the projectName
                                textInputAction: TextInputAction.go,
                              ),
                              searchBTButton(context),
                            ],
                          );
                        });
                    }),
                IconButton(icon: const Icon(Icons.home),
                  onPressed: () {
                    while(Navigator.of(context).canPop()) {
                      print("pop");
                      Navigator.of(context).pop();
                    }
                    PageActivities(0);
                  }),
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
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _addActivity();
              },
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.add),
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
}