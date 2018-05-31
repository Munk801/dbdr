import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'environment.dart';
import 'perk.dart';

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
        title: new Text('$roleString builds'.toUpperCase()),
      ),
      body: new StreamBuilder(
        stream: PerkManager.sharedInstance.getUserBuilds(role: role, uid: currentUser.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          return new ListView.builder(
            itemCount: snapshot.data.documents.length, //builds.length,
            padding: const EdgeInsets.only(top: 10.0),
            itemExtent: 100.0,
            itemBuilder: (context, index) {
              // var perkMap = snapshot.data;
              // var buildName = perkMap['name'];
              // var perk1 = _getPerkFromID(perkMap['perk1']);
              // var perk2 = _getPerkFromID(perkMap['perk2']);
              // var perk3 = _getPerkFromID(perkMap['perk3']);
              // var perk4 = _getPerkFromID(perkMap['perk4']);

              var ds = snapshot.data.documents[index];
              var buildName = ds['name'];
              var perk1 = _getPerkFromID(ds['perk1']);
              var perk2 = _getPerkFromID(ds['perk2']);
              var perk3 = _getPerkFromID(ds['perk3']);
              var perk4 = _getPerkFromID(ds['perk4']);
              return new BuildListViewCell(buildName: buildName, perk1: perk1, perk2: perk2, perk3: perk3, perk4: perk4);
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
        child: new Padding(
          padding: const EdgeInsets.all(4.0),
          child: new Column(
            children: [
              new Row(
                children: [
                  new Expanded(
                    child: new Text(buildName, style: Theme.of(context).primaryTextTheme.subhead,),
                  )
                ]
              ),
              new Row(children: [new Expanded(child: new Text(perk1.name)), new Expanded(child: new Text(perk2.name))]),
              new Row(children: [new Expanded(child: new Text(perk3.name)), new Expanded(child: new Text(perk4.name))]),
            ],
      ),
        ),
      ),
    );
  }
}