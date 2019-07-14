// Dart
import 'dart:async';
import 'dart:math';
import 'dart:io';

// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter/services.dart' show rootBundle;


// Internal Packages
import 'build_list.dart';
import 'constants.dart';
import 'environment.dart';
import 'perk.dart';
import 'perk_list.dart';
import 'storage_manager.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

FirebaseAnalytics analytics = FirebaseAnalytics();
FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

void main() async {
  rootBundle.loadString('FIREBASE_APIKEY.txt').then((config){ 
    FirebaseApp.configure(
      name: 'DBDR',
      options: new FirebaseOptions(
        googleAppID: Platform.isIOS
            ? '1:612079491419:ios:472df683bdd23490'
            : '1:612079491419:android:472df683bdd23490',
        gcmSenderID: '612079491419',
        apiKey: config,
        projectID: 'dbdr-6fbb1',
      ),
    ).then((app) {
      DBDRStorageManager.sharedInstance.initialize(app: app);
      PerkManager.sharedInstance.initialize(app: app);
      runApp(new MyApp());
    });
  });
}

TextTheme _buildDBDTextTheme(TextTheme base) {
  return base
      .copyWith(
        title: base.title.copyWith(fontWeight: FontWeight.w300, fontSize: 20.0),
        headline: base.headline.copyWith(fontWeight: FontWeight.w800),
        caption: base.caption.copyWith(fontWeight: FontWeight.w200, fontSize: 14.0),
        body1: base.body1.copyWith(fontWeight: FontWeight.w300, fontSize: 16.0)
      )
      .apply(
        fontFamily: "Open Sans",
      );
}

ThemeData _buildTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    accentColor: kDbdRed,
    textTheme: _buildDBDTextTheme(base.textTheme),
    primaryTextTheme: _buildDBDTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildDBDTextTheme(base.accentTextTheme)
  );
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DBD:R',
      home: MyHomePage(title: 'DBD:R', observer: observer),
      theme: _buildTheme(),
      navigatorObservers: [
        observer
      ],
      // debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title, this.observer}) : super(key: key);

  final String title;
  final FirebaseAnalyticsObserver observer;

  @override
  MyHomePageState createState() {
    return new MyHomePageState(observer);
  }
}

class MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  MyHomePageState(this.observer);

  final FirebaseAnalyticsObserver observer; 

  List<Perk> perkBuild = [];
  List<Perk> killerPerkBuild = [];
  int numPerks = 4;
  FirebaseUser currentUser;
  TabController _tabController;
  int selectedIndex = 0;

  final buildTextEditingController = new TextEditingController();

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 2, initialIndex: selectedIndex);
    _tabController.addListener(() { 
      setState(() {
        if (selectedIndex != _tabController.index) {
          selectedIndex = _tabController.index;
          _sendCurrentTabToAnalytics();
        }
      });
    });
    // Initialize the build with empty perks
    for (var i = 0; i < 4; i++) {
      perkBuild.add(new Perk.empty());
      killerPerkBuild.add(new Perk.empty());
    }

    // Attempt to sign in anonymously to save builds
    _auth.signInAnonymously()
      .then((user) { 
        currentUser = user;
        PerkManager.sharedInstance.getAll().then((onReturn) {
          _randomizePerks(PlayerRole.survivor);
          _randomizePerks(PlayerRole.killer);
        });
      }).catchError((e) {
      print("Error while signing in: $e");
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    buildTextEditingController.dispose();
    super.dispose();
  }

  void _signInAnonymously(BuildContext context) {
    _auth
      .signInAnonymously()
      .then((user) => currentUser = user)
      .catchError((e) {
        print("Error while signing in: $e");
      });
  }

  PlayerRole _getRoleFromTabIndex() {
    var role = _tabController.index == 0 ? PlayerRole.survivor : PlayerRole.killer;
    return role;
  }

  bool _checkLoggedInStatus(BuildContext context) {
    if (currentUser == null) {
      Scaffold.of(context).showSnackBar(
        new SnackBar(
          content: new Text("Unable to connect to server.",),
          action: new SnackBarAction(
            label: "Retry", 
            onPressed: () {
             _signInAnonymously(context); 
            },
          )
        ),
      );
      return false;
    }
    return true;
  }

  Future<Null> _navigateAndDisplayBuildListView(BuildContext context) async {
    if (!_checkLoggedInStatus(context)) {return;}
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor ? PerkManager.sharedInstance.survivorPerks : PerkManager.sharedInstance.killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new BuildListView(
          currentUser: currentUser, 
          perks: perkList, 
          role: role
        ),
        settings: RouteSettings(name: "BuildList")
      ),
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
      if (role == PlayerRole.survivor) {
        perkBuild = newPerkBuild;
      } else {
        killerPerkBuild = newPerkBuild;
      }
    });
  }

  _navigateAndDisplayPerkListView(BuildContext context, int index) async {
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor ? PerkManager.sharedInstance.survivorPerks: PerkManager.sharedInstance.killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new PerkListView(
          perks: perkList, 
          role: role
        ),
        settings: RouteSettings(name: "PerkList")
      ),
    );{
    if (result == null) 
      return;
    }
    setState(() {
      switch (role) {
        case PlayerRole.survivor:
          perkBuild[index] = result;
          break;
        case PlayerRole.killer:
          killerPerkBuild[index] = result;
          break;
        default:
          break;
      }
    });
  }

  _randomizePerks(PlayerRole role) {
    var perkList = List<Perk>();
    switch (role) {
      case PlayerRole.survivor:
        perkList = PerkManager.sharedInstance.survivorPerks;
        break;
      case PlayerRole.killer:
        perkList = PerkManager.sharedInstance.killerPerks;
        break;
      default:
        print("Unable to find role");
        break;
    }
    List<Perk> newPerkBuild = [];
    List<int> selected = [];
    var seed = new DateTime.now().microsecondsSinceEpoch;
    var random = Random(seed);
    for (var i = 0; i < 4; i++) {
      var randomIndex = random.nextInt(perkList.length);
      while(selected.contains(randomIndex)) {
        print("Random Index: $randomIndex.  Contained status: ${selected.contains(randomIndex)}");
        randomIndex = random.nextInt(perkList.length);
      }
      var perkToAdd = perkList[randomIndex];
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

  Future _favoriteBuild(PlayerRole role) async {
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
  }

  void _showFavoriteBuildDialog(BuildContext context) {
    if (!_checkLoggedInStatus(context)) {return;}
    showDialog(
      context: context,
      builder: (dialogContext) {
        var role = _getRoleFromTabIndex();
        return new BuildNameAlertDialog(buildTextEditingController, (isSuccess) {
          if (isSuccess) {
            _favoriteBuild(role).then((noop) => buildTextEditingController.clear());
            Scaffold.of(context).showSnackBar(
              new SnackBar(
                content: new Text(
                  "Build has been saved.", 
                  textAlign: TextAlign.center, 
                  style: Theme.of(context).primaryTextTheme.subhead,),
              )
            );
          }
          // Pop and remove text of build name from text controller
          Navigator.of(dialogContext).pop();
        });
      },
    ).then((value) {
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

void _sendCurrentTabToAnalytics() {
  var role = _getRoleFromTabIndex();
  var roleString = role == PlayerRole.survivor ? 'survivor' : 'killer';
  var screenName = 'PerksScreen:$roleString';
  print("Sending analytics: $screenName");
  this.observer.analytics.setCurrentScreen(screenName:  screenName);
}

  @override
  Widget build(BuildContext context) {
    var survivorPerkSlotViews = _createPerkSlotFromBuild(perkBuild);
    var killerPerkSlotViews = _createPerkSlotFromBuild(killerPerkBuild);
    return new Scaffold(
      appBar: new AppBar(
        bottom: new TabBar(
          indicatorColor: Theme.of(context).accentColor,
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
          new Builder(
            builder: (context) {
              return new IconButton(
                onPressed: () {
                  _navigateAndDisplayBuildListView(context);
                }, 
                icon: const Icon(Icons.more_vert)
              );
            }
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
      title: new Text("Name Your Build".toUpperCase(), style: Theme.of(context).primaryTextTheme.subhead),
      content: new Form(
        child: new TextFormField(
        controller: buildTextEditingController,
      )),
      actions: <Widget>[
        new FlatButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(const Radius.circular(8.0))),
          color: Theme.of(context).primaryColor,
          onPressed: () => completion(false),
          child: new Text("Cancel".toUpperCase(), style: Theme.of(context).primaryTextTheme.button),
        ),
        new FlatButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(const Radius.circular(8.0))),
          color: Theme.of(context).accentColor,
          onPressed: () => completion(true),
          child: new Text("Done".toUpperCase(), style: Theme.of(context).primaryTextTheme.button),
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
    return new OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
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
    } else {
      return new Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 60.0),
        child: new Row(
          children: columnChildren.map((perk) => new Expanded(child: perk)).toList(),
        ),
      );
    }
    },);
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
    Widget thumbnail = Container();
    if (perk.thumbnail != "") {
      thumbnail = new FadeInImage.memoryNetwork(
        image: perk.thumbnail,
        placeholder: kTransparentImage,
      );
    }
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
            child: new Stack(
              alignment: Alignment.topCenter,
              children: [
                new Column(
                  children: <Widget>[
                    new Expanded(
                      child: thumbnail,
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
                    onPressed: _handleTap, 
                    icon: const Icon(Icons.list)
                  )
                ),
              ]
            ),
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
    Widget thumbnail = Container();
    if (perk.thumbnail != "") {
      thumbnail = new FadeInImage.memoryNetwork(
        image: perk.thumbnail,
        placeholder: kTransparentImage,
      );
    }

    return new Padding(
      padding: const EdgeInsets.all(20.0),
      child: new Container(
        color: kDbdRed,
        child: new Column(
          children: <Widget>[
            new Expanded(
              child: thumbnail,
            ),
            new Text(
              perk.name.toUpperCase(),
              style: Theme.of(context).primaryTextTheme.headline,
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


