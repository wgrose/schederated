import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Lists'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/profile');
            },
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) => ListView(
          children: [
            for (final list in appState.lists)
              ListTile(
                leading: const Icon(Icons.list),
                title: Text(list.title),
                subtitle: Text(list.created.toString()),
                onTap: () {
                  context.push('/lists/${list.id}');
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/new-list');
        },
        tooltip: 'Create List',
        child: const Icon(Icons.add),
      ),
    );
  }
}
