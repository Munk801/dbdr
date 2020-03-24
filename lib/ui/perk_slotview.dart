import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:dbdr/perk.dart';
import 'package:dbdr/constants.dart';

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

class PerkSlotView extends StatefulWidget {
  const PerkSlotView({Key key, this.perk, this.index, this.onListPressed})
      : super(key: key);
  final Perk perk;
  final int index;
  final ValueChanged<int> onListPressed;

  @override
  PerkDescriptiveSlotViewState createState() => PerkDescriptiveSlotViewState();
}

class PerkSlotViewState extends State<PerkSlotView> {
  bool isLocked = false;
  IconData lockIconData;
  Color lockColor;

  @override
  void initState() {
    super.initState();
    this.lockIconData = getLockIcon();
    this.lockColor = this.getLockColor();
  }

  IconData getLockIcon() {
    return this.isLocked ? Icons.lock : Icons.lock_open;
  }

  Color getLockColor() {
    return this.isLocked ? kDbdMutedRed : kDbdGrey;
  }

  void _handleTap() {
    widget.onListPressed(widget.index);
  }

  void _handleLockTapped() {
    this.isLocked = !this.isLocked;
    setState(() {
      this.lockIconData = this.getLockIcon();
      this.lockColor = this.getLockColor();
    });
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
    return new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new GestureDetector(
        onTap: () {
          showModalBottomSheet(
              context: context,
              builder: (buildContext) {
                return new PerkDescriptionSheet(widget.perk);
              });
        },
        child: Card(
          // shape: const _DiamondBorder(),
          color: this.lockColor,
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
                      widget.perk.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
                new Align(
                  alignment: Alignment.topLeft,
                  child: new IconButton(
                    onPressed: _handleLockTapped, 
                    icon: new Icon(this.lockIconData),
                  )
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

class PerkDescriptiveSlotViewState extends State<PerkSlotView> {
  bool isLocked = false;
  IconData lockIconData;
  Color lockColor;

  @override
  void initState() {
    super.initState();
    this.lockIconData = getLockIcon();
    this.lockColor = this.getLockColor();
  }

  IconData getLockIcon() {
    return this.isLocked ? Icons.lock : Icons.lock_open;
  }

  Color getLockColor() {
    return this.isLocked ? kDbdMutedRed : kDbdGrey;
  }

  void _handleTap() {
    widget.onListPressed(widget.index);
  }

  void _handleLockTapped() {
    this.isLocked = !this.isLocked;
    setState(() {
      this.lockIconData = this.getLockIcon();
      this.lockColor = this.getLockColor();
    });
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
          showModalBottomSheet(
              context: context,
              builder: (buildContext) {
                return new PerkDescriptionSheet(widget.perk);
              });
        },
        child: Card(
          color: this.lockColor,
          // color: kDbdRed,
          elevation: 8.0,
          child: new Container(
            padding: EdgeInsets.all(5.0),
            child: Row(
              children: <Widget>[
                new Expanded(
                  flex: 1,
                  child: SizedBox(
                    child: thumbnail,
                    height: 150,
                  ),
                ),
                new Expanded(
                  flex: 2,
                  child: new Column(
                    children: <Widget>[
                      new Text(
                        widget.perk.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      new Text(
                        widget.perk.description,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.body1,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                )
              ],
            ),
          ),
        ),
      );
  }
}