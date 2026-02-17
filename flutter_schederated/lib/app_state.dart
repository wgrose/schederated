import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart'; // new
import 'package:flutter/material.dart';
import 'dart:async'; 

import 'config.dart'; // new
import 'firebase_options.dart';
import 'lists.dart'; // new

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
      GoogleProvider(clientId: googleClientId), // new
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _listsSubscription = FirebaseFirestore.instance
            .collection('lists')
            .where('members', arrayContains: user.uid) // updated
            .orderBy('created', descending: true)
            .withConverter<SchederatedList>(
              fromFirestore: SchederatedList.fromFirestore,
              toFirestore: (SchederatedList list, _) => list.toFirestore(),
            )
            .snapshots()
            .listen((snapshot) {
          _lists = [];
          for (final document in snapshot.docs) {
            _lists.add(document.data());
          }
          notifyListeners();
        });
      } else {
        _loggedIn = false;
        _lists = [];
        _listsSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  StreamSubscription<QuerySnapshot<SchederatedList>>? _listsSubscription;
  List<SchederatedList> _lists = [];
  List<SchederatedList> get lists => _lists;
}
