
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'perk.dart';
import 'storage_manager.dart';

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
    Widget thumbnail = Container();
    if (widget.perk.thumbnail != "") {
      thumbnail = new FadeInImage.memoryNetwork(
        image: widget.perk.thumbnail,
        placeholder: kTransparentImage,
      );
    }
    return new GestureDetector(
      onTap: () {
        Navigator.pop(context, widget.perk);
      },
      child: new Card(
        child: new Row(
          children: <Widget>[
            thumbnail,
            new Expanded(
              child: new Text(widget.perk.name.toUpperCase()),
            )
          ]
        ),
      ),
    );
  }
}