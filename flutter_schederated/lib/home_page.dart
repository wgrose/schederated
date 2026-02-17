import 'package:firebase_auth/firebase_auth.dart' // new
    hide EmailAuthProvider, PhoneAuthProvider;    // new
import 'package:flutter/material.dart';           // new
import 'package:provider/provider.dart';          // new
import 'package:go_router/go_router.dart';

import 'app_state.dart';                          // new
import 'src/authentication.dart';                 // new
import 'src/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('lsha.re'),
        actions: [
          Consumer<ApplicationState>(
            builder: (context, appState, _) => appState.loggedIn
                ? Row(
                    children: [
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
                  )
                : TextButton(
                    onPressed: () {
                      context.push('/sign-in');
                    },
                    child: const Text('Sign In'),
                  ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Consumer<ApplicationState>(
            builder: (context, appState, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header('What is this app?'),
                const Paragraph(
                  'An AI powered smart list sharing app for families and friends. Create an account to get started.',
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StyledButton(
                    onPressed: () {
                      context.push('/sign-in');
                    },
                    child: const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
