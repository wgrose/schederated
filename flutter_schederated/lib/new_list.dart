import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewList extends StatefulWidget {
  const NewList({super.key});

  @override
  State<NewList> createState() => _NewListState();
}

class _NewListState extends State<NewList> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  Future<void> _createList() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('lists').add({
        'title': _controller.text,
        'created': FieldValue.serverTimestamp(),
        'creator': FirebaseAuth.instance.currentUser!.uid,
        'members': [FirebaseAuth.instance.currentUser!.uid], // new
      });
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'List Title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createList,
                child: const Text('Create List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
