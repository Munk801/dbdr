import 'package:flutter/material.dart';

showPerkBuildDeletionSnackBar(BuildContext context) {
  Scaffold.of(context).showSnackBar(new SnackBar(
        content: const Text(
          "Removed Build",
        ),
      ));
}
