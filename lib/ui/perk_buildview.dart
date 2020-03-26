
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


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


class PerkDescriptiveBuildView extends StatelessWidget {
  final List<Widget> columnChildren;

  PerkDescriptiveBuildView(this.columnChildren);

  @override
  Widget build(BuildContext context) {
    return new OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return new LayoutBuilder(
          builder: (layoutContext, constraints) {
            // Get the container height to match the phone size
            // We want 20 pixels ot define any extra controls we want
            var buildContainerHeight = (constraints.maxHeight / 4.0) - 20.0;
            return ListView.builder(
              padding: EdgeInsets.all(5.0),
              itemCount: columnChildren.length,
              itemBuilder: (BuildContext context, int index) {
                var widget = this.columnChildren[index];
                return Container(height: buildContainerHeight, child: widget,);
              },
            );
          }
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

