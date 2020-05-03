
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dbdr/perk.dart';
import 'package:dbdr/constants.dart';
import 'package:dbdr/storage_manager.dart';

///A sheet that displays the perk descriptions.
///Required to provide a [perk] object to define
///which perk to display the information.
class PerkDescriptionSheet extends StatelessWidget {
  final Perk perk;
  final String role;
  final VoidCallback onClose;

  PerkDescriptionSheet({@required this.perk, @required this.role, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      color: kDbdGrey,
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
              child: PerkThumbnailBox(perk: perk, role: this.role),
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
            child: SubheadTextWidget(text: "description")
          ),
          Expanded(
            flex: 1,
            child: BodyTextWidget(text: perk.description),
          ),
          Expanded(
            flex: 0,
            child: SubheadTextWidget(text: "perk owner")
          ),
          Expanded(
            flex: 0,
            child: BodyTextWidget(text: perk.owner),
          ),
          Expanded(
            flex: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_drop_down_circle), 
              onPressed: () {if (this.onClose != null) {this.onClose(); }},
            )
          )
        ],
      ),
    );
  }
}

class BodyTextWidget extends StatelessWidget {
  const BodyTextWidget({
    Key key,
    @required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.body1,
      ),
    );
  }
}

class SubheadTextWidget extends StatelessWidget {
  final String text;

  const SubheadTextWidget({
    Key key,
    this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.left,
        style: Theme.of(context).primaryTextTheme.subhead,
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
                return new PerkDescriptionSheet(perk: widget.perk, role: this.role);
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
                  role: this.role,
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
                  child:  PerkThumbnailBox(
                    role: this.role, 
                    perk: widget.perk,
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

class PerkThumbnailBox extends StatelessWidget {
  const PerkThumbnailBox({
    Key key,
    @required this.perk,
    @required this.role
  }) : super(key: key);

  final Perk perk;
  final String role;

  @override
  Widget build(BuildContext context) {
    if (this.perk.thumbnail == "") {
      DBDRStorageManager.sharedInstance
        .getPerkImageURL(this.perk)
        .then((image) {
          this.perk.thumbnail = image;
        });
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: ValueListenableBuilder(
          valueListenable: this.perk.thumbnailNotifier,
          builder: (valueContext, value, _) {
            if (value == "") {
              return Container(width: 100.0, height: 100.0);
            }
            else {
              return FadeInImage.assetNetwork(
                image: this.perk.thumbnail,
                placeholder: "assets/icons/${this.role}.png",
              );
            }
          }
        ),
      ),
    );
  }
}