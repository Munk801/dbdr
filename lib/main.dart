// Dart
import 'dart:async';
import 'dart:math';
import 'dart:io';

// External Packages 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

// Internal Packages
import 'perk.dart';


class _DiamondBorder extends ShapeBorder {
  const _DiamondBorder();

  @override
  EdgeInsetsGeometry get dimensions {
    return const EdgeInsets.only();
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..moveTo(rect.left + rect.width / 2.0, rect.top)
      ..lineTo(rect.right, rect.top + rect.height / 2.0)
      ..lineTo(rect.left + rect.width  / 2.0, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height / 2.0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {}

  // This border doesn't support scaling.
  @override
  ShapeBorder scale(double t) {
    return null;
  }
}

class DBDRStorageManager {
  static final sharedInstance = new DBDRStorageManager();
  FirebaseStorage storage;

  Future<Null> initialize() async {
    await FirebaseApp.configure(
      name: 'DBDR',
      options: new FirebaseOptions(
        googleAppID: Platform.isIOS
            ? '1:612079491419:ios:472df683bdd23490'
            : '1:612079491419:android:472df683bdd23490',
        gcmSenderID: '612079491419',
        apiKey: 'AIzaSyAf4e2fO674CDoZ66LQxjqi5wvV2yR_SlM',
        projectID: 'dbdr-6fbb1',
      ),
    ).then((app) {
      this.storage = new FirebaseStorage(app: app, storageBucket: 'gs://dbdr-6fbb1.appspot.com');
    });
  }

  Future<String> getPerkImageURL(Perk perk) async {
    var assetUrl =  '/images/perks/${perk.id}.png';
    print("Perk Image: $assetUrl");
    var url = await storage.ref().child(assetUrl).getDownloadURL();
    return url; 
  }
}

void main() async {
  DBDRStorageManager.sharedInstance.initialize();
  runApp(new MyApp());

}
ThemeData _buildTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    // cardColor: Colors.grey,
  );
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DBDR',
      home: MyHomePage(title: 'DBDR'),
      theme: _buildTheme(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);


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
  List<String> perkImageUrls = [];

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
    for (var i = 0; i < 4; i++) {
      setState(() {
        perkBuild.add(new Perk.empty());
      });
    }
    super.initState();
  }

  void _randomizePerks() {
    List<Perk> newPerkBuild = [];
    List<int> selected = [];
    for (var i = 0; i < 4; i ++) {
      var randomIndex = Random().nextInt(perks.length);
      // Ensure that we never get the same perk in the same slot
      while (selected.contains(randomIndex)) {randomIndex = Random().nextInt(perks.length);}
      var perkToAdd = perks[randomIndex];
      // Retrieve the perk image and add it to the perk
      DBDRStorageManager.sharedInstance.getPerkImageURL(perkToAdd).then((image) {
        setState(() {
          perkToAdd.thumbnail = image;
        });
      });
      newPerkBuild.add(perkToAdd);
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
      columnChildren = perkBuild.map((perk) => PerkSlotView(perk: perk)).toList();
    }    
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title)),
      body: new Container(
          color: Colors.white,
          child: new PerkBuildView(columnChildren),
        ),
      floatingActionButton: new FloatingActionButton(
        child: const Icon(Icons.swap_calls),
        onPressed: _randomizePerks,
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

class PerkBuildView extends StatelessWidget {
  final List<Widget> columnChildren;

  PerkBuildView(this.columnChildren);

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (layoutContext, constraints) {
        var width = constraints.maxWidth / 2;
        var top = 0.0;
        var topLeft = (constraints.maxWidth / 2) - (width / 2); 
        var midTop = top + (width);
        var bottomTop = midTop + (width);
        return new Stack(
          alignment: AlignmentDirectional.center,
          children: [
            new Positioned(top: top, left: topLeft, width: width, height: width, child: columnChildren[0]),
            new Positioned(top: midTop, left: 0.5, width: width, height: width, child: columnChildren[1]),
            new Positioned(top: midTop, left: width, width: width, height: width, child: columnChildren[2]),
            new Positioned(top: bottomTop, left: topLeft, width: width, height: width, child: columnChildren[3]),
          ]
        );

    },);
  }
}

class PerkSlotView extends StatelessWidget {
  const PerkSlotView({Key key, this.perk}) : super(key: key);
  final Perk perk;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new Card(
        // shape: const _DiamondBorder(),
        color: Theme.of(context).cardColor,
        elevation: 8.0,
        child: new Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              new Expanded(
              child: new FadeInImage.memoryNetwork(
                  image: perk.thumbnail,
                  placeholder: kTransparentImage,
                ),
              ),
              new Text(perk.name, style: Theme.of(context).textTheme.caption,), 
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
