// Dart
import 'dart:async';
import 'dart:math';
import 'dart:io';

// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

// Internal Packages
import 'constants.dart';
import 'perk.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class _DiamondBorder extends ShapeBorder {
  const _DiamondBorder();

  @override
  EdgeInsetsGeometry get dimensions {
    return const EdgeInsets.only();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return new Path()
      ..moveTo(rect.left + rect.width / 2.0, rect.top)
      ..lineTo(rect.right, rect.top + rect.height / 2.0)
      ..lineTo(rect.left + rect.width / 2.0, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height / 2.0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

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
    await FirebaseApp
        .configure(
      name: 'DBDR',
      options: new FirebaseOptions(
        googleAppID: Platform.isIOS
            ? '1:612079491419:ios:472df683bdd23490'
            : '1:612079491419:android:472df683bdd23490',
        gcmSenderID: '612079491419',
        apiKey: Platform.environment['FIREBASE_DBDR_APIKEY'],
        projectID: 'dbdr-6fbb1',
      ),
    )
        .then((app) {
      this.storage = new FirebaseStorage(
          app: app, storageBucket: 'gs://dbdr-6fbb1.appspot.com');
    });
  }

  Future<String> getPerkImageURL(Perk perk) async {
    var assetUrl = '/images/perks/${perk.id}.png';
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
    accentColor: kDbdRed,
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

  @override
  MyHomePageState createState() {
    return new MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  List<Perk> perks = [];
  List<Perk> perkBuild = [];
  int numPerks = 4;
  FirebaseUser currentUser;

  final buildTextEditingController = new TextEditingController();

  _getPerks(QuerySnapshot query) {
    for (var document in query.documents) {
      var perk = Perk.fromDocument(document);
      setState(() => perks.add(perk));
    }
    _randomizePerks();
  }

  @override
  void initState() {
    var perksRef =
        Firestore.instance.collection('perks').getDocuments().then(_getPerks);
    for (var i = 0; i < 4; i++) {
      perkBuild.add(new Perk.empty());
    }
    _auth.signInAnonymously().then((user) => currentUser = user);
    super.initState();
  }

  _navigateAndDisplayBuildListView(BuildContext context) async {
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new BuildListView(currentUser: currentUser)),
    );
    if (result == null) {
      return;
    }
  }


  _navigateAndDisplayPerkListView(BuildContext context, int index) async {
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new PerkListView()),
    );
    if (result == null) {
      return;
    }
    setState(() {
      perkBuild[index] = result;
    });
  }

  _randomizePerks() {
    List<Perk> newPerkBuild = [];
    List<int> selected = [];
    for (var i = 0; i < 4; i++) {
      var randomIndex = Random().nextInt(perks.length);
      // Ensure that we never get the same perk in the same slot
      while (selected.contains(randomIndex)) {
        randomIndex = Random().nextInt(perks.length);
      }
      var perkToAdd = perks[randomIndex];
      // Retrieve the perk image and add it to the perk
      DBDRStorageManager.sharedInstance
          .getPerkImageURL(perkToAdd)
          .then((image) {
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

  Future<Null> _favoriteBuild() async {
    if (currentUser == null) {
      return;
    }
    var name = buildTextEditingController.text;
    var buildData = {"user": currentUser.uid, "name": name, "perk1": perkBuild[0].id, "perk2": perkBuild[1].id, "perk3": perkBuild[2].id, "perk4": perkBuild[3].id}; 
    await Firestore.instance.collection("builds").add(buildData);
    return;
  }

  @override
  Widget build(BuildContext context) {
    var perkSlotViews = List<Widget>();
    for (var i = 0; i < 4; i++) {
      var slotView = new PerkSlotView(
          perk: perkBuild[i],
          index: i,
          onListPressed: (index) =>
              _navigateAndDisplayPerkListView(context, index));
      perkSlotViews.add(slotView);
    }
    return new DefaultTabController(
        length: 2,
        child: new Scaffold(
            appBar: new AppBar(
              bottom: new TabBar(tabs: [
                new Tab(
                  child: new Text("Survivor".toUpperCase()),
                ),
                new Tab(child: new Text("Killer".toUpperCase())),
              ]),
              title: new Text(widget.title),
              actions: [
                new IconButton(
                    onPressed: () {
                      return showDialog(
                        context: context,
                        builder: (context) {
                          return new BuildNameAlertDialog(buildTextEditingController, (isSuccess) {
                            if (isSuccess) {
                              _favoriteBuild().then((_) {
                                Navigator.of(context).pop();
                              });
                            }
                          });
                        },
                      );
                    },
                    icon: const Icon(Icons.favorite)),
                new IconButton(
                    onPressed: () {
                      _navigateAndDisplayBuildListView(context);
                    }, 
                    icon: const Icon(Icons.more_vert)
                ),
              ],
            ),
            body: new TabBarView(children: [
              new Container(
                color: Theme.of(context).backgroundColor,
                child: new PerkBuildView(perkSlotViews),
              ),
              new Container(
                color: Theme.of(context).backgroundColor,
                child: new PerkBuildView(perkSlotViews),
              ),
            ]),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: new FloatingActionButton.extended(
              onPressed: _randomizePerks,
              backgroundColor: Theme.of(context).accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.swap_calls),
              label: new Text("Randomize".toUpperCase()),
            )));
  }
}

class BuildNameAlertDialog extends StatelessWidget {
  final TextEditingController buildTextEditingController;
  final ValueChanged<bool> completion; 

  BuildNameAlertDialog(this.buildTextEditingController, this.completion);

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: const Text("Name Your Build"),
      content: new Form(
          child: new TextFormField(
        controller: buildTextEditingController,
      )),
      actions: <Widget>[
        new FlatButton(
            onPressed: () {completion(false);},
            child: const Text("Cancel")),
        new FlatButton(
          onPressed: () {completion(true);},
          child: const Text("Done"),
        )
      ],
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
        var height = constraints.maxHeight / 3.33;
        var top = 0.0;
        var topLeft = (constraints.maxWidth / 2) - (width / 2);
        var midTop = top + (height);
        var bottomTop = midTop + (height);
        return new Stack(alignment: AlignmentDirectional.center, children: [
          new Positioned(
              top: top,
              left: topLeft,
              width: width,
              height: height,
              child: columnChildren[0]),
          new Positioned(
              top: midTop,
              left: 0.5,
              width: width,
              height: height,
              child: columnChildren[1]),
          new Positioned(
              top: midTop,
              left: width,
              width: width,
              height: height,
              child: columnChildren[2]),
          new Positioned(
              top: bottomTop,
              left: topLeft,
              width: width,
              height: height,
              child: columnChildren[3]),
        ]);
      },
    );
  }
}

class PerkSlotView extends StatelessWidget {
  const PerkSlotView({Key key, this.perk, this.index, this.onListPressed})
      : super(key: key);
  final Perk perk;
  final int index;
  final ValueChanged<int> onListPressed;

  void _handleTap() {
    onListPressed(index);
  }

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new GestureDetector(
        onTap: () {
          showModalBottomSheet(
              context: context,
              builder: (buildContext) {
                return new PerkDescriptionSheet(perk);
              });
        },
        child: Card(
          // shape: const _DiamondBorder(),
          color: Theme.of(context).primaryColor,
          elevation: 8.0,
          child: new Padding(
            padding: const EdgeInsets.all(5.0),
            child: new Stack(children: [
              new Column(
                children: <Widget>[
                  new Expanded(
                    child: new FadeInImage.memoryNetwork(
                      image: perk.thumbnail,
                      placeholder: kTransparentImage,
                    ),
                  ),
                  new Text(
                    perk.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
              new Align(
                  alignment: Alignment.topRight,
                  child: new IconButton(
                      onPressed: _handleTap, icon: const Icon(Icons.list))),
            ]),
          ),
        ),
      ),
    );
  }
}

class PerkDescriptionSheet extends StatelessWidget {
  final Perk perk;

  PerkDescriptionSheet(this.perk);

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(20.0),
      child: new Container(
        color: Colors.grey,
        child: new Column(
          children: <Widget>[
            new Expanded(
              child: new FadeInImage.memoryNetwork(
                image: perk.thumbnail,
                placeholder: kTransparentImage,
              ),
            ),
            new Text(
              perk.name.toUpperCase(),
              style: Theme.of(context).textTheme.headline,
            ),
            new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Text(
                perk.description,
                style: Theme.of(context).textTheme.body1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BuildListView extends StatelessWidget {

  BuildListView({this.currentUser});
  final FirebaseUser currentUser;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          leading: new BackButton(),
          centerTitle: true,
          title: const Text('Select a Build'),
        ),
        body: new StreamBuilder(
            stream: Firestore.instance.collection('builds').where("user", isEqualTo: currentUser.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Loading...');
              return new ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  padding: const EdgeInsets.only(top: 10.0),
                  itemExtent: 55.0,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.documents[index];
                    return new BuildListViewCell(ds);
                  });
            }));
  }
}

class BuildListViewCell extends StatelessWidget {
  final DocumentSnapshot document;

  BuildListViewCell(this.document);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: new Card(
        child: new Row(
          children: [
            new Expanded(
              child: new Text(document["name"]),
            )
          ]
        )
      ),
    );
  }
}

class PerkListView extends StatelessWidget {
  final List<Perk> perks;

  PerkListView({this.perks});

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          leading: new BackButton(),
          centerTitle: true,
          title: const Text('Select Perk'),
        ),
        body: new StreamBuilder(
            stream: Firestore.instance.collection('perks').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Loading...');
              return new ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  padding: const EdgeInsets.only(top: 10.0),
                  itemExtent: 55.0,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.documents[index];
                    Perk perk = Perk.fromDocument(ds);
                    return new PerkListViewCell(perk);
                  });
            }));
  }
}

class PerkListViewCell extends StatefulWidget {
  final Perk perk;

  PerkListViewCell(this.perk);

  @override
  PerkListViewCellState createState() {
    return new PerkListViewCellState();
  }
}

class PerkListViewCellState extends State<PerkListViewCell> {
  @override
  void initState() {
    DBDRStorageManager.sharedInstance
        .getPerkImageURL(widget.perk)
        .then((image) {
      setState(() {
        widget.perk.thumbnail = image;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pop(context, widget.perk);
      },
      child: new Card(
          child: new Row(children: <Widget>[
        new FadeInImage.memoryNetwork(
          image: widget.perk.thumbnail,
          placeholder: kTransparentImage,
        ),
        new Expanded(
          child: new Text(widget.perk.name.toUpperCase()),
        )
      ])),
    );
  }
}
