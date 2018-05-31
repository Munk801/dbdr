import 'package:cloud_firestore/cloud_firestore.dart';

class Perk {
  String id, name, description;
  String thumbnail = "";

  Perk(this.id, this.name, this.description);

  Perk.empty() : this("", "", "");

  Perk.fromDocument(DocumentSnapshot document) {
    id = document.documentID;
    name = document['name'];
    description = document['description'];
  }
}

class PerkBuild {
  
}