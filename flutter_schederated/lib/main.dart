import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'join_page.dart';
import 'list_page.dart';
import 'lists_page.dart';
import 'new_list.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const App()),
  ));
}

// Add GoRouter configuration inside the App class
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationState>();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'lists',
              builder: (context, state) => const ListsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final join = state.uri.queryParameters['join'] == 'true';
                    return ListPage(listId: id, join: join);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'join/:inviteId',
              builder: (context, state) {
                final inviteId = state.pathParameters['inviteId']!;
                return JoinPage(inviteId: inviteId);
              },
            ),
            GoRoute(
              path: 'new-list',
              builder: (context, state) {
                return const NewList();
              },
            ),
            GoRoute(
              path: 'sign-in',
              builder: (context, state) {
                return SignInScreen(
                  actions: [
                    ForgotPasswordAction(((context, email) {
                      final uri = Uri(
                        path: '/sign-in/forgot-password',
                        queryParameters: <String, String?>{
                          'email': email,
                        },
                      );
                      context.push(uri.toString());
                    })),
                    AuthStateChangeAction(((context, state) {
                      final user = switch (state) {
                        SignedIn state => state.user,
                        UserCreated state => state.credential.user,
                        _ => null
                      };
                      if (user == null) {
                        return;
                      }
                      if (state is UserCreated) {
                        user.updateDisplayName(user.email!.split('@')[0]);
                      }
                      if (!user.emailVerified) {
                        user.sendEmailVerification();
                        const snackBar = SnackBar(
                            content: Text(
                                'Please check your email to verify your email address'));
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                      context.pushReplacement('/lists');
                    })),
                  ],
                  showPasswordVisibilityToggle: true,
                );
              },
              routes: [
                GoRoute(
                  path: 'forgot-password',
                  builder: (context, state) {
                    final arguments = state.uri.queryParameters;
                    return ForgotPasswordScreen(
                      email: arguments['email'],
                      headerMaxExtent: 200,
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'profile',
              builder: (context, state) {
                return ProfileScreen(
                  providers: const [],
                  actions: [
                    SignedOutAction((context) {
                      context.pushReplacement('/');
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final loggedIn = appState.loggedIn;
        final isLoggingIn = state.uri.toString() == '/sign-in';
        final isCreatingList = state.uri.toString() == '/new-list';
        if (loggedIn && isLoggingIn) return '/lists';
        if (!loggedIn && isCreatingList) return '/sign-in';
        
        return null;
      },
      refreshListenable: appState,
    );

     return MaterialApp.router(
      title: 'List Share - http://lsha.re',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
