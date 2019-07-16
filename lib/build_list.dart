import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'constants.dart';
import 'environment.dart';
import 'perk.dart';
import 'scaffold_utilities.dart';
import 'storage_manager.dart';

class BuildListView extends StatelessWidget {
  BuildListView({this.currentUser, this.perks, this.role});
  final FirebaseUser currentUser;
  final List<Perk> perks;
  final PlayerRole role;

  Perk _getPerkFromID(String perkId) {
    var perkIndex = perks.indexWhere((perk) => perk.id == perkId);
    if (perkIndex == -1) {
      return null;
    }
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
            stream: PerkManager.sharedInstance
                .getUserBuilds(role: role, uid: currentUser.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Loading...');
              return new ListView.builder(
                itemCount: snapshot.data.documents.length, //builds.length,
                padding: const EdgeInsets.only(top: 10.0),
                // itemExtent: 100.0,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];
                  var id = ds.documentID;
                  var buildName = ds['name'];
                  var perk1 = _getPerkFromID(ds['perk1']);
                  var perk2 = _getPerkFromID(ds['perk2']);
                  var perk3 = _getPerkFromID(ds['perk3']);
                  var perk4 = _getPerkFromID(ds['perk4']);
                  return new Dismissible(
                    key: new Key(id),
                    confirmDismiss: (direction) {
                      return showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return new ConfirmDeleteBuildDialog((shouldDelete) => Navigator.of(context).pop(shouldDelete));
                        }
                      );
                    },
                    onDismissed: (direction) {
                      PerkManager.sharedInstance.removeBuild(id).then((_) {
                        showPerkBuildDeletionSnackBar(context);
                      });
                    },
                    background: new Container(
                      color: kDbdRed, 
                      child: new Align(
                        alignment: const Alignment(0.8, 0.0),
                        child: const Text('DELETE'),
                        ) 
                      ),
                    child: BuildListViewCell(
                        buildName: buildName,
                        perk1: perk1,
                        perk2: perk2,
                        perk3: perk3,
                        perk4: perk4),
                  );
                },
              );
            }));
  }
}

class ConfirmDeleteBuildDialog extends StatelessWidget {
  final ValueChanged<bool> completion; 

  ConfirmDeleteBuildDialog(this.completion);

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: new Text("This will delete your build.  Are you sure you would like to delete?".toUpperCase(), style: Theme.of(context).primaryTextTheme.subhead),
      actions: <Widget>[
        new FlatButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(const Radius.circular(8.0))),
          color: Theme.of(context).primaryColor,
          onPressed: () => completion(false),
          child: new Text("No".toUpperCase(), style: Theme.of(context).primaryTextTheme.button),
        ),
        new FlatButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(const Radius.circular(8.0))),
          color: Theme.of(context).accentColor,
          onPressed: () => completion(true),
          child: new Text("Yes".toUpperCase(), style: Theme.of(context).primaryTextTheme.button),
        )
      ],
    );
  }
}

class BuildListViewCell extends StatelessWidget {
  final String buildName;
  final Perk perk1, perk2, perk3, perk4;

  BuildListViewCell(
      {this.buildName, this.perk1, this.perk2, this.perk3, this.perk4});

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pop(context,
            {"perk1": perk1, "perk2": perk2, "perk3": perk3, "perk4": perk4});
      },
      child: new Card(
        color: Theme.of(context).primaryColor,
        child: new Padding(
          padding: const EdgeInsets.all(10.0),
          child: new Column(
            children: [
              new Row(children: [
                new Expanded(
                  child: new Text(
                    buildName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.subhead,
                  ),
                )
              ]),
              new Row(children: [
                new PerkThumbnail(perk: perk1),
                new PerkThumbnail(perk: perk2),
                new PerkThumbnail(perk: perk3),
                new PerkThumbnail(perk: perk4),
              ]),
              // new Row(children: [
              //   new PerkThumbnail(perk: perk3),
              //   new PerkThumbnail(perk: perk4),
              // ])
            ],
          ),
        ),
      ),
    );
  }
}

class PerkThumbnail extends StatefulWidget {
  const PerkThumbnail({
    Key key,
    @required this.perk,
  }) : super(key: key);

  final Perk perk;

  @override
  PerkThumbnailState createState() {
    return new PerkThumbnailState();
  }
}

class PerkThumbnailState extends State<PerkThumbnail> {
  Perk perk;

  @override
  void initState() {
    perk = widget.perk;
    if (perk.thumbnail == "") {
      DBDRStorageManager.sharedInstance
        .getPerkImageURL(perk)
        .then((image) {
          setState(() => perk.thumbnail = image);
        });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget thumbnail = new Container();
    if (perk.thumbnail != "") {
      thumbnail = new FadeInImage.memoryNetwork(
        image: perk.thumbnail,
        width: 120.0,
        placeholder: kTransparentImage,
      );
    } else {
    }
    return new Expanded(
      child: Column(
        children: <Widget>[
          thumbnail,
          new Text(widget.perk.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.caption,),
        ],
      ),
    );
  }
}
