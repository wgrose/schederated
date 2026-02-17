import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key, required this.inviteId});
  final String inviteId;

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  String _status = 'Joining...';

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        // Redirect to sign in, but we'd lose the deep link context in basic implementation.
        // Ideally, GoRouter redirect handles this.
        // For now, show message.
        setState(() {
          _status = 'Please sign in to join this list.';
        });
        // Optional: Auto-redirect manually
        context.push('/sign-in'); 
      }
      return;
    }

    try {
      // 1. Fetch Invite
      final inviteDoc = await FirebaseFirestore.instance
          .collection('invites')
          .doc(widget.inviteId)
          .get();

      if (!inviteDoc.exists) {
        setState(() => _status = 'Invalid or expired invite link.');
        return;
      }

      final listId = inviteDoc.data()?['listId'] as String?;
      if (listId == null) {
        setState(() => _status = 'Invalid invite data.');
        return;
      }

      // 2. Add user to list members
      await FirebaseFirestore.instance.collection('lists').doc(listId).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      // 3. Redirect to List
      if (mounted) {
        context.go('/lists/$listId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error joining list: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Joining List')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            if (_status.contains('sign in'))
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: () => context.push('/sign-in'),
                  child: const Text('Sign In'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
