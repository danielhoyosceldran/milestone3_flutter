import 'package:intellij_project/tree.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}