
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:dbdr/ui/perk_slotview.dart';
import 'package:dbdr/constants.dart';
import 'package:dbdr/environment.dart';
import 'package:dbdr/perk.dart';

class PerkListView extends StatelessWidget {
  final List<Perk> perks;
  final PlayerRole role;

  PerkListView({this.perks, this.role});

  @override
  Widget build(BuildContext context) {
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
            PerkManager.sharedInstance.perks(role, ignoreFiltered: true)[index],
            this.role.shortString(),
          );
        }
      ),
    );
  }
}

class PerkListViewCell extends StatefulWidget {
  final Perk perk;
  final String role;

  PerkListViewCell(this.perk, this.role);

  @override
  PerkListViewCellState createState() {
    return new PerkListViewCellState();
  }
}

class PerkListViewCellState extends State<PerkListViewCell> {
  FadeInImage thumbnail;

  @override
  void initState() {
    super.initState();
    this.thumbnail = new FadeInImage.memoryNetwork(
      image: widget.perk.thumbnail,
      placeholder: kTransparentImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pop(context, widget.perk);
      },
      child: new Card(
        child: new Row(
          children: <Widget>[
            PerkThumbnailBox(perk: null, role: null),
            new Expanded(
              child: new Text(widget.perk.name.toUpperCase()),
            )
          ]
        ),
      ),
    );
  }
}


class FilterPerkListView extends StatelessWidget {
  final List<Perk> perks;
  final PlayerRole role;

  FilterPerkListView({this.perks, this.role});

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new BackButton(),
        centerTitle: true,
        title: const Text('FILTER PERKS'),
      ),
      body: new ListView.builder(
        itemCount: PerkManager.sharedInstance.flattenedOwnerPerkList(role).length,
        padding: const EdgeInsets.only(top: 10.0),
        itemExtent: 55.0,
        itemBuilder: (context, index) {
          var item = PerkManager.sharedInstance.flattenedOwnerPerkList(role)[index];
          if (item is String) {
            return new ListTile(title: Text(item, style: Theme.of(context).textTheme.headline));
          }
          else {
            return new FilterPerkListViewCell(
              item,
              role
            );
          }
        }
      ),
    );
  }
}

class FilterPerkListViewCell extends StatefulWidget {
  final Perk perk;
  final PlayerRole role;

  FilterPerkListViewCell(this.perk, this.role);

  @override
  FilterPerkListViewCellState createState() {
    return new FilterPerkListViewCellState();
  }
}

class FilterPerkListViewCellState extends State<FilterPerkListViewCell> {
  Perk perk;
  String role;

  @override
  void initState() {
    super.initState();
    this.role = this.widget.role.shortString();
    this.perk = widget.perk;
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        setState(() {
          widget.perk.isFiltered = !widget.perk.isFiltered;
        });
      },
      child: new Card(
        color: widget.perk.isFiltered ? mainTheme.primaryColor : mainTheme.primaryColorLight,
        child: new Row(
          children: <Widget>[
            new Expanded(
              flex: 1,
              child: Container(child: PerkThumbnailBox(perk: this.perk, role: this.role)),
            ),
            new Expanded(
              flex: 4,
              child: new Text(widget.perk.name.toUpperCase()),
            )
          ]
        ),
      ),
    );
  }
}