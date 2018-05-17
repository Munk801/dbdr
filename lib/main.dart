// Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Internal
import 'perk.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DBDR',
      home: MyHomePage(title: 'DBDR'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;


  @override
  MyHomePageState createState() {
    return new MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  List<Perk> perks = [];
  List<Perk> perkBuild = [];
  int numPerks = 4;

  @override
  void initState() {
    var perksRef = Firestore.instance
        .collection('perks')
        .getDocuments()
        .then((querySnapshot) {
      for (var document in querySnapshot.documents) {
        var perk = Perk(document['name'], document['description']);
        setState(() {
          perks.add(perk);
        });
      }
    });
    super.initState();
  }

  void _randomizePerks() {
    List<Perk> newPerkBuild = [];
    for (var i = 0; i < 4; i ++) {
      var randomIndex = Random().nextInt(perks.length);
      newPerkBuild.add(perks[randomIndex]);
    }
    setState(() {
      perkBuild = newPerkBuild;
    });

  }

  @override
  Widget build(BuildContext context) {
    var columnChildren = List<Widget>();
    if (perkBuild.length == numPerks) {
      columnChildren = [
        new PerkSlotView(perk: perkBuild[0]),
        new PerkSlotView(perk: perkBuild[1]),
        new PerkSlotView(perk: perkBuild[2]),
        new PerkSlotView(perk: perkBuild[3]),
      ];
    }
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title)),
      body: new Container(
          color: Colors.white,
          child: new Column(
            children: columnChildren,
          )),
      floatingActionButton: new FloatingActionButton(
        onPressed: _randomizePerks,
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

class PerkSlotView extends StatelessWidget {
  const PerkSlotView({Key key, this.perk}) : super(key: key);
  final Perk perk;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(20.0),
      child: new Column(
        children: <Widget>[new Text(perk.name), new Text(perk.description)],
      ),
    );
  }
}

class PerkListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new StreamBuilder(
        stream: Firestore.instance.collection('perks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          return new ListView.builder(
              itemCount: snapshot.data.documents.length,
              padding: const EdgeInsets.only(top: 10.0),
              itemExtent: 55.0,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.documents[index];
                return new Text(" ${ds['name']} ${ds['description']}");
              });
        });
  }
}
