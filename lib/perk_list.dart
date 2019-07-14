
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'environment.dart';
import 'perk.dart';

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
      body: new ListView.builder(
        itemCount: PerkManager.sharedInstance.perks(role).length,
        padding: const EdgeInsets.only(top: 10.0),
        itemExtent: 55.0,
        itemBuilder: (context, index) {
          return new PerkListViewCell(
            PerkManager.sharedInstance.perks(role)[index]
          );
        }
      ),
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