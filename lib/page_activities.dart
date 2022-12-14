import 'package:intellij_project/tree.dart';
import 'package:intellij_project/PageIntervals.dart';
import 'package:flutter/material.dart';

class PageActivities extends StatefulWidget {
  @override
  _PageActivitiesState createState() => _PageActivitiesState();
}

class _PageActivitiesState extends State<PageActivities> {
  late Tree tree;

  @override
  void initState() {
    super.initState();
    tree = getTree();
  }

  void _navigateDownIntervals(int childId) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => PageIntervals())
    );
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
    // split by '.' and taking first element of resulting list
    // removes the microseconds part
    assert (activity is Project || activity is Task);
    if (activity is Project) {
      return ListTile(
        title: Text('${activity.name}'),
        trailing: Text('$strDuration'),
        leading: const Icon(Icons.folder),
        iconColor: Colors.blueGrey,
        onTap: () => {},
        // TODO, navigate down to show children tasks and projects
      );
    } else {
      Task task = activity as Task;
      Widget trailing;
      trailing = Text('$strDuration');
      return ListTile(
        title: Text('${activity.name}'),
        trailing: trailing,
        onTap: () => _navigateDownIntervals(index),
        onLongPress: () {}, // TODO start/stop counting the time for this task
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Time Tracker"),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.home),
              onPressed: () {}
            // TODO go home page = root
          ),
          //TODO other actions
        ],
      ),
      body: ListView.separated(
        // it's like ListView.builder() but better
        // because it includes a separator between items
        padding: const EdgeInsets.all(16.0),
        itemCount: tree.root.children.length,
        itemBuilder: (BuildContext context, int index) =>
            _buildRow(tree.root.children[index], index),
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
  }
}