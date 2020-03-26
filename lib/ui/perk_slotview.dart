
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:dbdr/perk.dart';
import 'package:dbdr/constants.dart';
import 'package:dbdr/shape_utilities.dart';

///A sheet that displays the perk descriptions.
///Required to provide a [perk] object to define
///which perk to display the information.
class PerkDescriptionSheet extends StatelessWidget {
  final Perk perk;
  final VoidCallback onClose;

  PerkDescriptionSheet({@required this.perk, this.onClose});

  @override
  Widget build(BuildContext context) {
    Widget thumbnail = Container(width: 150.0, height: 150.0);
    // if (perk.thumbnail != "") {
    //   thumbnail = FadeInImage.memoryNetwork(
    //     image: perk.thumbnail,
    //     placeholder: kTransparentImage,
    //   );
    // }

    return Container(
      padding: EdgeInsets.all(20.0),
      color: kDbdGrey,
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: kDbdRed,
                shape: DiamondBorder()),
                child: thumbnail,
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                perk.name.toUpperCase(),
                style: Theme.of(context).primaryTextTheme.headline,
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              alignment: Alignment.centerLeft,
              child: Text(
                "description".toUpperCase(),
                textAlign: TextAlign.left,
                style: Theme.of(context).primaryTextTheme.subhead,
              ),
            )
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                perk.description,
                style: Theme.of(context).textTheme.body1,
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_drop_down_circle), 
              onPressed: () {this.onClose();},
            )
          )
        ],
      ),
    );
  }
}

class PerkSlotView extends StatefulWidget {
  const PerkSlotView({Key key, this.perk, this.role, this.index, this.onListPressed})
      : super(key: key);
  final Perk perk;
  final PlayerRole role;
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
    Widget thumbnail = Container(width: 150.0, height: 150.0);
    // if (widget.perk.thumbnail != "") {
    //   thumbnail = new FadeInImage.memoryNetwork(
    //     image: widget.perk.thumbnail,
    //     placeholder: kTransparentImage,
    //   );
    // }
    return new Padding(
      padding: const EdgeInsets.all(5.0),
      child: new GestureDetector(
        onTap: () {
          showModalBottomSheet(
              context: context,
              builder: (buildContext) {
                return new PerkDescriptionSheet(perk: widget.perk);
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
  String role;

  @override
  void initState() {
    super.initState();
    this.lockIconData = getLockIcon();
    this.lockColor = this.getLockColor();
    this.role = widget.role == PlayerRole.survivor ? "survivor" : "killer";
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
    return new GestureDetector(
        onTap: () {
          showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (buildContext) {
                PerkDescriptionSheet sheet = PerkDescriptionSheet(
                  perk: widget.perk, 
                  onClose: () => Navigator.of(buildContext).pop()
                );
                return sheet;
              });
        },
        child: Card(
          color: this.lockColor,
          // color: kDbdRed,
          elevation: 8.0,
          child: Container(
            padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child:  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: ValueListenableBuilder(
                        valueListenable: widget.perk.thumbnailNotifier,
                        builder: (valueContext, value, _) {
                          if (value == "") {
                            return Container(width: 150.0, height: 150.0);
                          }
                          else {
                            return FadeInImage.assetNetwork(
                              image: widget.perk.thumbnail,
                              placeholder: "assets/icons/${this.role}.png",
                            );
                          }
                        }
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        flex: 0,
                        child: Container(
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 5.0),
                          child: Text(
                            widget.perk.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.subtitle,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          widget.perk.description,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.caption,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex:1,
                        child: ButtonBar(
                          children: <Widget>[
                            IconButton(
                              onPressed: _handleLockTapped, 
                              icon: Icon(this.lockIconData),
                            ),
                            IconButton(
                              onPressed: _handleTap, 
                              icon: const Icon(Icons.list)
                            ),
                          ],
                        )
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