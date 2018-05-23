// Dart
import 'dart:async';
import 'dart:math';

// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

// Internal Packages
import 'constants.dart';
import 'perk.dart';
import 'storage_manager.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

enum PlayerRole {survivor, killer}

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
      title: 'DBD:R',
      home: MyHomePage(title: 'DBD:R'),
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

class MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  List<Perk> perks = [];
  List<Perk> killerPerks = [];
  List<Perk> perkBuild = [];
  List<Perk> killerPerkBuild = [];
  int numPerks = 4;
  FirebaseUser currentUser;
  TabController _tabController;

  final buildTextEditingController = new TextEditingController();

  _getPerks(QuerySnapshot query) {
    for (var document in query.documents) {
      var perk = Perk.fromDocument(document);
      setState(() => perks.add(perk));
    }
    _randomizePerks(PlayerRole.survivor);
  }

  _getKillerPerks(QuerySnapshot query) {
    for (var document in query.documents) {
      var perk = Perk.fromDocument(document);
      setState(() => killerPerks.add(perk));
    }
    _randomizePerks(PlayerRole.killer);
  }


  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 2);
    // Retrieve all the perks
    Firestore.instance.collection('perks').where('role', isEqualTo: 'survivor').getDocuments().then(_getPerks);
    Firestore.instance.collection('perks').where('role', isEqualTo: 'killer').getDocuments().then(_getKillerPerks);
    for (var i = 0; i < 4; i++) {
      perkBuild.add(new Perk.empty());
      killerPerkBuild.add(new Perk.empty());
    }
    _auth.signInAnonymously().then((user) => currentUser = user);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    buildTextEditingController.dispose();
    super.dispose();
  }

  PlayerRole _getRoleFromTabIndex() {
    var role = _tabController.index == 0 ? PlayerRole.survivor : PlayerRole.killer;
    return role;
  }

  _navigateAndDisplayBuildListView(BuildContext context) async {
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor ? perks : killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new BuildListView(currentUser: currentUser, perks: perkList, role: role)),
    );
    if (result == null) {
      return;
    }
    var newPerkBuild = <Perk>[
      result['perk1'],
      result['perk2'],
      result['perk3'],
      result['perk4']
    ];
    for (var perk in newPerkBuild) {
      DBDRStorageManager.sharedInstance
          .getPerkImageURL(perk)
          .then((image) {
        setState(() {
          perk.thumbnail = image;
        });
      });
    }
    setState(() {
      perkBuild = newPerkBuild;
    });
  }


  _navigateAndDisplayPerkListView(BuildContext context, int index) async {
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor ? perks : killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new PerkListView(perks: perkList, role: role)),
    );{
    if (result == null) 
      return;
    }
    setState(() {
      perkBuild[index] = result;
    });
  }

  _randomizePerks(PlayerRole role) {
    var perkList = List<Perk>();
    switch (role) {
      case PlayerRole.survivor:
        perkList = perks;
        break;
      case PlayerRole.killer:
        perkList = killerPerks;
        break;
      default:
        print("Unable to find role");
        break;
    }
    List<Perk> newPerkBuild = [];
    List<int> selected = [];
    for (var i = 0; i < 4; i++) {
      var randomIndex = Random().nextInt(perkList.length);
      // Ensure that we never get the same perk in the same slot
      while (selected.contains(randomIndex)) {
        randomIndex = Random().nextInt(perkList.length);
      }
      var perkToAdd = perkList [randomIndex];
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
    switch (role) {
      case PlayerRole.survivor:
        setState(() {
          perkBuild = newPerkBuild;
        });
        break;
      case PlayerRole.killer:
        setState(() {
          killerPerkBuild = newPerkBuild;
        });
        break;
      default:
        break;
    }
  }

  Future<Null> _favoriteBuild(PlayerRole role) async {
    if (currentUser == null) {
      return;
    }
    var perkList = role == PlayerRole.survivor ? perkBuild : killerPerkBuild;
    var roleString = role == PlayerRole.survivor ? 'survivor' : 'killer';
    var name = buildTextEditingController.text;
    var buildData = {
      "user": currentUser.uid, 
      "name": name, 
      "perk1": perkList[0].id, 
      "perk2": perkList[1].id,
      "perk3": perkList[2].id, 
      "perk4": perkList[3].id,
      "role": roleString,
    }; 
    await Firestore.instance.collection("builds").add(buildData);
    return;
  }

  _showFavoriteBuildDialog(BuildContext context) {
   return showDialog(
    context: context,
    builder: (dialogContext) {
      var role = _getRoleFromTabIndex();
      return new BuildNameAlertDialog(buildTextEditingController, (isSuccess) {
        if (isSuccess) {
          _favoriteBuild(role);
        }
        Navigator.of(dialogContext).pop();
      });
    },
  ).then((value) {
    Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Build has been saved")));
  }); 
}

List<Widget> _createPerkSlotFromBuild(List<Perk> perkBuild) {
  var perkSlotViews = List<Widget>();
  for (var i = 0; i < 4; i++) {
    var slotView = new PerkSlotView(
        perk: perkBuild[i],
        index: i,
        onListPressed: (index) =>
            _navigateAndDisplayPerkListView(context, index));
    perkSlotViews.add(slotView);
  }
  return perkSlotViews;
}

  @override
  Widget build(BuildContext context) {
    var survivorPerkSlotViews = _createPerkSlotFromBuild(perkBuild);
    var killerPerkSlotViews = _createPerkSlotFromBuild(killerPerkBuild);
    return new Scaffold(
      appBar: new AppBar(
        bottom: new TabBar(
          controller: _tabController,
          tabs: [
            new Tab(child: new Text("Survivor".toUpperCase())),
            new Tab(child: new Text("Killer".toUpperCase())),
          ]
        ),
        title: new Text(widget.title),
        actions: [
          new Builder(
            builder: (context) {
              return new IconButton(
                onPressed: () => _showFavoriteBuildDialog(context),
                icon: const Icon(Icons.favorite),
              );
            }
          ),
          new IconButton(
            onPressed: () {
                _navigateAndDisplayBuildListView(context);
            }, 
            icon: const Icon(Icons.more_vert)
          ),
        ],
      ),
      body: new TabBarView(
        controller: _tabController,
        children: [
          new Container(
            color: Theme.of(context).backgroundColor,
            child: new PerkBuildView(survivorPerkSlotViews),
          ),
          new Container(
            color: Theme.of(context).backgroundColor,
            child: new PerkBuildView(killerPerkSlotViews),
          ),
        ]
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: new FloatingActionButton.extended(
        onPressed: () {
          var role = _getRoleFromTabIndex();
          _randomizePerks(role);
        },
        backgroundColor: Theme.of(context).accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.swap_calls),
        label: new Text("Randomize".toUpperCase()),
      )
    );
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
          // color: kDbdRed,
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
              style: Theme.of(context).accentTextTheme.headline,
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
  BuildListView({this.currentUser, this.perks, this.role});
  final FirebaseUser currentUser;
  final List<Perk> perks;
  final PlayerRole role;

  Perk _getPerkFromID(String perkId) {
    var perkIndex = perks.indexWhere((perk) => perk.id == perkId);
    if (perkIndex == -1) { return null; }
    return perks[perkIndex];
  }

  @override
  Widget build(BuildContext context) {
    var roleString = role == PlayerRole.survivor ? 'survivor' : 'killer';
    return new Scaffold(
      appBar: new AppBar(
        leading: new BackButton(),
        centerTitle: true,
        title: const Text('Select a Build'),
      ),
      body: new StreamBuilder(
        stream: Firestore.instance.collection('builds').where("user", isEqualTo: currentUser.uid).where('role', isEqualTo: roleString).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          return new ListView.builder(
            itemCount: snapshot.data.documents.length,
            padding: const EdgeInsets.only(top: 10.0),
            itemExtent: 80.0,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data.documents[index];
              var perk1 = _getPerkFromID(ds['perk1']);
              var perk2 = _getPerkFromID(ds['perk2']);
              var perk3 = _getPerkFromID(ds['perk3']);
              var perk4 = _getPerkFromID(ds['perk4']);
              return new BuildListViewCell(buildName: ds['name'], perk1: perk1, perk2: perk2, perk3: perk3, perk4: perk4);
            }
          );
        }
      )
    );
  }
}

class BuildListViewCell extends StatelessWidget {
  final String buildName;
  final Perk perk1, perk2, perk3, perk4;

  BuildListViewCell({this.buildName, this.perk1, this.perk2, this.perk3, this.perk4});

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pop(context, {"perk1": perk1, "perk2": perk2, "perk3": perk3, "perk4": perk4});
      },
      child: new Card(
        child: new Column(
          children: [
            new Row(
              children: [
                new Expanded(
                  child: new Text(buildName),
                )
              ]
            ),
            new Row(children: [new Expanded(child: new Text(perk1.name)), new Expanded(child: new Text(perk2.name))]),
            new Row(children: [new Expanded(child: new Text(perk3.name)), new Expanded(child: new Text(perk4.name))]),
          ],
      ),
      ),
    );
  }
}

class PerkListView extends StatelessWidget {
  final List<Perk> perks;
  final PlayerRole role;

  PerkListView({this.perks, this.role});

  @override
  Widget build(BuildContext context) {
    var roleString = role == PlayerRole.survivor ? "survivor" : "killer";
    return new Scaffold(
      appBar: new AppBar(
        leading: new BackButton(),
        centerTitle: true,
        title: const Text('Select Perk'),
      ),
      body: new StreamBuilder(
        stream: Firestore.instance.collection('perks').where('role', isEqualTo: roleString).snapshots(),
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
            }
          );
        }
      )
    );
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
