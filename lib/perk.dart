import 'package:cloud_firestore/cloud_firestore.dart';

class Perk {
  String name;
  String description;

  Perk(this.name, this.description);

  Perk.fromDocument(DocumentSnapshot document) {
    name = document['name'];
    description = document['description'];
  }
}