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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;

// Internal Packages
import 'package:dbdr/ui/perk_slotview.dart';
import 'package:dbdr/ui/perk_buildview.dart';
import 'build_list.dart';
import 'constants.dart';
import 'environment.dart';
import 'perk.dart';
import 'perk_list.dart';
import 'storage_manager.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

FirebaseAnalytics analytics = FirebaseAnalytics();
FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  rootBundle.loadString('FIREBASE_APIKEY.txt').then((config) {
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

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'DBD:R',
      home: MyHomePage(
        title: 'DBD RANDOMIZER',
        observer: observer,
      ),
      theme: mainTheme,
      navigatorObservers: [observer],
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

class MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  MyHomePageState(this.observer);

  final FirebaseAnalyticsObserver observer;

  List<Perk> perkBuild = [];
  List<Perk> killerPerkBuild = [];
  int numPerks = 4;
  FirebaseUser currentUser;
  TabController _tabController;
  int selectedIndex = 0;

  List<Widget> _survivorPerkSlotViews = [];
  List<Widget> _killerPerkSlotViews = [];

  List<GlobalKey<PerkSlotViewState>> _survivorPerkSlotKeys = [];
  List<GlobalKey<PerkSlotViewState>> _killerPerkSlotKeys = [];

  final buildTextEditingController = new TextEditingController();

  @override
  void initState() {
    _tabController =
        TabController(vsync: this, length: 2, initialIndex: selectedIndex);
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
      _survivorPerkSlotKeys.add(new GlobalKey<PerkSlotViewState>());
      _killerPerkSlotKeys.add(new GlobalKey<PerkSlotViewState>());
    }

    // Attempt to sign in anonymously to save builds
    _auth.signInAnonymously().then((user) {
      currentUser = user;
      DBDRStorageManager.sharedInstance.user = user;
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
    var role =
        _tabController.index == 0 ? PlayerRole.survivor : PlayerRole.killer;
    return role;
  }

  bool _checkLoggedInStatus(BuildContext context) {
    if (currentUser == null) {
      Scaffold.of(context).showSnackBar(
        new SnackBar(
            content: new Text(
              "Unable to connect to server.",
            ),
            action: new SnackBarAction(
              label: "Retry",
              onPressed: () {
                _signInAnonymously(context);
              },
            )),
      );
      return false;
    }
    return true;
  }

  Future<Null> _navigateAndDisplayBuildListView(BuildContext context) async {
    if (!_checkLoggedInStatus(context)) {
      return;
    }
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor
        ? PerkManager.sharedInstance.survivorPerks
        : PerkManager.sharedInstance.killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) => new BuildListView(
              currentUser: currentUser, perks: perkList, role: role),
          settings: RouteSettings(name: "BuildList")),
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
    setState(() {
      if (role == PlayerRole.survivor) {
        perkBuild = newPerkBuild;
      } else {
        killerPerkBuild = newPerkBuild;
      }
    });
  }

  Map<int, Perk> _getLockedPerks(PlayerRole role) {
    Map<int, Perk> lockedPerks = {};
    if (role == PlayerRole.survivor) {
      for (var i = 0; i < 4; i++) {
        var slotKey = _survivorPerkSlotKeys[i];
        if (slotKey.currentState != null && slotKey.currentState.isLocked) {
          var perk = _survivorPerkSlotKeys[i].currentState.widget.perk;
          lockedPerks[i] = perk;
        }
      }
    } else {
      for (var i = 0; i < 4; i++) {
        var slotKey = _killerPerkSlotKeys[i];
        if (slotKey.currentState != null && slotKey.currentState.isLocked) {
          var perk = _killerPerkSlotKeys[i].currentState.widget.perk;
          lockedPerks[i] = perk;
        }
      }
    }
    return lockedPerks;
  }

  _navigateAndDisplayPerkListView(BuildContext context, int index) async {
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor
        ? PerkManager.sharedInstance.survivorPerks
        : PerkManager.sharedInstance.killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) => new PerkListView(perks: perkList, role: role),
          settings: RouteSettings(name: "PerkList")),
    );
    {
      if (result == null) return;
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

  void _randomizePerks(PlayerRole role) {
    var perkList = List<Perk>();
    List<Perk> newPerkBuild = [];
    Map<int, Perk> lockedPerks = {};
    List<int> selected = [];
    perkList = PerkManager.sharedInstance.perks(role, ignoreFiltered: true);
    lockedPerks = this._getLockedPerks(role);
    var seed = new DateTime.now().microsecondsSinceEpoch;
    var random = Random(seed);
    for (var i = 0; i < 4; i++) {
      // If the locked perk is in this slot, add that perk back to the build.
      if (lockedPerks.keys.contains(i)) {
        newPerkBuild.add(lockedPerks[i]);
        var index = perkList.indexOf(lockedPerks[i]);
        selected.add(index);
        continue;
      }
      var randomIndex = random.nextInt(perkList.length);
      while (selected.contains(randomIndex)) {
        randomIndex = random.nextInt(perkList.length);
      }
      var perkToAdd = perkList[randomIndex];
      if (perkToAdd.thumbnail == "") {
        // Retrieve the perk image and add it to the perk
        DBDRStorageManager.sharedInstance
            .getPerkImageURL(perkToAdd)
            .then((image) {
          setState(() {
            perkToAdd.thumbnail = image;
          });
        });
      }
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
    this.observer.analytics.logEvent(name: "randomized_perks");
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
    this
        .observer
        .analytics
        .logEvent(name: "favorited_build", parameters: buildData);
  }

  void _showFavoriteBuildDialog(BuildContext context) {
    if (!_checkLoggedInStatus(context)) {
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) {
        var role = _getRoleFromTabIndex();
        return new BuildNameAlertDialog(buildTextEditingController,
            (isSuccess) {
          if (isSuccess) {
            _favoriteBuild(role)
                .then((noop) => buildTextEditingController.clear());
            Scaffold.of(context).showSnackBar(new SnackBar(
              content: new Text(
                "Build has been saved.",
                textAlign: TextAlign.center,
                style: Theme.of(context).primaryTextTheme.subtitle1,
              ),
            ));
          }
          // Pop and remove text of build name from text controller
          Navigator.of(dialogContext).pop();
        });
      },
    ).then((value) {});
  }

  void _showFilterPerksScreen(BuildContext context) async {
    var role = _getRoleFromTabIndex();
    var perkList = role == PlayerRole.survivor
        ? PerkManager.sharedInstance.survivorPerks
        : PerkManager.sharedInstance.killerPerks;
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) =>
              new FilterPerkListView(perks: perkList, role: role),
          settings: RouteSettings(name: "FilterPerks")),
    );
    {
      if (result == null) return;
    }
  }

  List<Widget> _createPerkSlotFromBuild(List<Perk> perkBuild, PlayerRole role) {
    var perkSlotViews = List<Widget>();
    var perkKeys = role == PlayerRole.survivor
        ? _survivorPerkSlotKeys
        : _killerPerkSlotKeys;
    for (var i = 0; i < 4; i++) {
      var slotView = new PerkSlotView(
          perk: perkBuild[i],
          role: role,
          index: i,
          key: perkKeys[i],
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
    this.observer.analytics.setCurrentScreen(screenName: screenName);
  }

  @override
  Widget build(BuildContext context) {
    this._survivorPerkSlotViews =
        _createPerkSlotFromBuild(perkBuild, PlayerRole.survivor);
    this._killerPerkSlotViews =
        _createPerkSlotFromBuild(killerPerkBuild, PlayerRole.killer);
    return new Scaffold(
        appBar: new AppBar(
          bottom: new TabBar(
              indicatorColor: Theme.of(context).accentColor,
              controller: _tabController,
              tabs: [
                new Tab(
                  icon: ImageIcon(AssetImage('assets/icons/survivor.png')),
                  text: "Survivor".toUpperCase(),
                ),
                new Tab(
                  icon: ImageIcon(AssetImage('assets/icons/killer.png')),
                  text: "Killer".toUpperCase(),
                ),
              ]),
          title: new Text(widget.title),
          centerTitle: true,
          leading: new Builder(builder: (context) {
            return new IconButton(
                onPressed: () => _showFilterPerksScreen(context),
                icon: Icon(Icons.filter_list));
          }),
          actions: [
            new Builder(builder: (context) {
              return new IconButton(
                onPressed: () => _showFavoriteBuildDialog(context),
                icon: const Icon(Icons.favorite),
              );
            }),
            new Builder(builder: (context) {
              return new IconButton(
                  onPressed: () {
                    _navigateAndDisplayBuildListView(context);
                  },
                  icon: const Icon(Icons.more_vert));
            }),
          ],
        ),
        body: new TabBarView(controller: _tabController, children: [
          new Container(
            color: Theme.of(context).backgroundColor,
            child: new PerkDescriptiveBuildView(this._survivorPerkSlotViews),
          ),
          new Container(
            color: Theme.of(context).backgroundColor,
            child: new PerkDescriptiveBuildView(this._killerPerkSlotViews),
          ),
        ]),
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
        ));
  }
}

class BuildNameAlertDialog extends StatelessWidget {
  final TextEditingController buildTextEditingController;
  final ValueChanged<bool> completion;

  BuildNameAlertDialog(this.buildTextEditingController, this.completion);

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: new Text("Name Your Build".toUpperCase(),
          style: Theme.of(context).primaryTextTheme.subtitle1),
      content: new Form(
          child: new TextFormField(
        controller: buildTextEditingController,
      )),
      actions: <Widget>[
        new FlatButton(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(const Radius.circular(8.0))),
          color: Theme.of(context).primaryColor,
          onPressed: () => completion(false),
          child: new Text("Cancel".toUpperCase(),
              style: Theme.of(context).primaryTextTheme.button),
        ),
        new FlatButton(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(const Radius.circular(8.0))),
          color: Theme.of(context).accentColor,
          onPressed: () => completion(true),
          child: new Text("Done".toUpperCase(),
              style: Theme.of(context).primaryTextTheme.button),
        )
      ],
    );
  }
}
