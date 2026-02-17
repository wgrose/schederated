import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // new

import 'lists.dart';
import 'package:flutter/services.dart'; // new
import 'src/widgets.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key, required this.listId, this.join = false});

  final String listId;
  final bool join;

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final _controller = TextEditingController();

  // Check if user is a member
  Future<bool> _isMember() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('lists').doc(widget.listId).get();
    final data = doc.data();
    if (data == null) return false;
    final members = List<String>.from(data['members'] as List? ?? []);
    return members.contains(user.uid);
  }

  Future<void> _joinList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance.collection('lists').doc(widget.listId).update({
      'members': FieldValue.arrayUnion([user.uid]),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined list!')),
      );
      setState(() {}); // Refresh UI
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.join) {
      _joinList();
    }
  }

  Future<String> _createInvite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Must be signed in');
    
    // Check if invite exists
    final query = await FirebaseFirestore.instance
        .collection('invites')
        .where('listId', isEqualTo: widget.listId)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new
    final doc = await FirebaseFirestore.instance.collection('invites').add({
      'listId': widget.listId,
      'created': FieldValue.serverTimestamp(),
      'creator': user.uid,
    });
    return doc.id;
  }

  Future<void> _addItem() async {
    if (_controller.text.isEmpty) return;
    
    await FirebaseFirestore.instance
        .collection('lists')
        .doc(widget.listId)
        .collection('items')
        .add({
      'text': _controller.text,
      'completed': false,
      'created': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('lists').doc(widget.listId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.data() != null) {
              return Text(snapshot.data!.data()!['title'] as String);
            }
            return const Text('Loading...');
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Share List'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          // Copy View Link (current URL clean)
                          final url = Uri.base.replace(queryParameters: {});
                          Clipboard.setData(ClipboardData(text: url.toString()));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View link copied!')),
                          );
                        },
                        child: const Text('Copy View Link (Read-Only)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () async {
                          // Copy Join Link (via invites collection)
                          Navigator.pop(context); // Close dialog first to avoid blocking? Or show generating?
                          // Let's keep dialog open or show loading. But easy way: close and toast "Generating..." if slow.
                          // Actually, just wait.
                          
                          try {
                            final inviteId = await _createInvite();
                            final url = Uri.base.replace(
                              path: '/join/$inviteId',
                              queryParameters: {},
                            );
                            Clipboard.setData(ClipboardData(text: url.toString()));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Join link copied!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating invite: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Copy Join Link (Edit Access)'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<bool>(
            future: _isMember(),
            builder: (context, snapshot) {
              final isMember = snapshot.data ?? false;
              if (!isMember) return const SizedBox.shrink(); // Hide input if not member

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Add an item...',
                        ),
                        onFieldSubmitted: (_) => _addItem(),
                      ),
                    ),
                    IconButton(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FirestoreListView<SchederatedItem>(
              query: FirebaseFirestore.instance
                  .collection('lists')
                  .doc(widget.listId)
                  .collection('items')
                  .orderBy('created')
                  .withConverter<SchederatedItem>(
                    fromFirestore: SchederatedItem.fromFirestore,
                    toFirestore: (SchederatedItem item, _) => item.toFirestore(),
                  ),
              itemBuilder: (context, snapshot) {
                final item = snapshot.data();
                return FutureBuilder<bool>(
                  future: _isMember(),
                  builder: (context, memberSnapshot) {
                    final isMember = memberSnapshot.data ?? false;
                    return CheckboxListTile(
                      value: item.completed,
                      title: Text(item.text),
                      onChanged: isMember ? (bool? value) {
                        if (value != null) {
                          snapshot.reference.update({'completed': value});
                        }
                      } : null, // Disable if not member
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
