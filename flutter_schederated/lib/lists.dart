import 'package:cloud_firestore/cloud_firestore.dart';

class SchederatedList {
  SchederatedList({required this.title, required this.created, required this.creator, required this.id, required this.members}); // updated

  final String title;
  final DateTime created;
  final String creator;
  final String id;
  final List<String> members; // new

  factory SchederatedList.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data();
    return SchederatedList(
      title: data?['title'] as String,
      created: (data?['created'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creator: data?['creator'] as String,
      id: snapshot.id,
      members: List<String>.from(data?['members'] as List? ?? []), // new
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'created': Timestamp.fromDate(created),
      'creator': creator,
      'members': members, // new
    };
  }
}

class SchederatedItem {
  SchederatedItem({required this.text, required this.completed, required this.created});

  final String text;
  final bool completed;
  final DateTime created;

  factory SchederatedItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data();
    return SchederatedItem(
      text: data?['text'] as String,
      completed: data?['completed'] as bool? ?? false,
      created: (data?['created'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'completed': completed,
      'created': Timestamp.fromDate(created),
    };
  }
}
