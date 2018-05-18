// Packages
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

// Internal
import 'perk.dart';

void main() async {
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'DBDR',
    options: new FirebaseOptions(
      googleAppID: Platform.isIOS
          ? '1:612079491419:ios:472df683bdd23490'
          : '1:612079491419:android:472df683bdd23490',
      gcmSenderID: '612079491419',
      apiKey: 'AIzaSyAf4e2fO674CDoZ66LQxjqi5wvV2yR_SlM',
      projectID: 'dbdr-6fbb1',
    ),
  );
  final FirebaseStorage storage = new FirebaseStorage(
      app: app, storageBucket: 'gs://dbdr-6fbb1.appspot.com');
  runApp(new MyApp(storage: storage));
  // runApp(new MyApp());

}

class MyApp extends StatelessWidget {
  MyApp({this.storage});
  final FirebaseStorage storage;
  // const MyApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DBDR',
      home: MyHomePage(title: 'DBDR', storage: storage,),
      // home: MyHomePage(title: 'DBDR'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title, this.storage}) : super(key: key);
  // const MyHomePage({Key key, this.title}) : super(key: key);


  final String title;
  final FirebaseStorage storage;


  @override
  MyHomePageState createState() {
    return new MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  List<Perk> perks = [];
  List<Perk> perkBuild = [];
  int numPerks = 4;
  String perkImageUrl = "";

  Future<String> getPerkURL() async {
    var url = await widget.storage.ref().child('/images/perks/ace_in_the_hole.png').getDownloadURL();
    print(url);
    return url;
  }

  @override
  void initState() {
    var perksRef = Firestore.instance
        .collection('perks')
        .getDocuments()
        .then((querySnapshot) {
      for (var document in querySnapshot.documents) {
        var perk = Perk.fromDocument(document);
        setState(() {
          perks.add(perk);
        });
      }
    });
    getPerkURL().then((url) {
      setState(() {
        perkImageUrl = url;
      });
    });
    super.initState();
  }

  void _randomizePerks() {
    List<Perk> newPerkBuild = [];
    List<int> selected = [];
    for (var i = 0; i < 4; i ++) {
      var randomIndex = Random().nextInt(perks.length);
      // Ensure that we never get the same perk in the same slot
      while (selected.contains(randomIndex)) {randomIndex = Random().nextInt(perks.length);}
      newPerkBuild.add(perks[randomIndex]);
      selected.add(randomIndex);
    }
    setState(() {
      perkBuild = newPerkBuild;
    });

  }

  @override
  Widget build(BuildContext context) {
    var columnChildren = List<Widget>();
    if (perkBuild.length == numPerks) {
      columnChildren = perkBuild.map((perk) => PerkSlotView(perk: perk, image: perkImageUrl)).toList();
    }
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title)),
      body: new Container(
          color: Colors.white,
          child: new GridView.count(
            crossAxisCount: 2,
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
  const PerkSlotView({Key key, this.perk, this.image}) : super(key: key);
  final Perk perk;
  final String image;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new Card(
        elevation: 8.0,
        child: new Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              new FadeInImage.memoryNetwork(
                image: image,
                placeholder: kTransparentImage,
              ),
              new Text(perk.name, style: Theme.of(context).textTheme.headline,), 
              new Text(perk.description, style: Theme.of(context).textTheme.body1)
            ],
          ),
        ),
      )
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
