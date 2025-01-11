// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitter/screens/sign_in_screen.dart';
import '../providers/app_state.dart';
import '../screens/transaction_group_screen.dart';
import '../dialogs/add_transaction_group_dialog.dart';
import '../dialogs/join_transaction_group_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {

        if (appState.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (appState.user == null) {
          return SignInScreen();
        }
        else {
          print("User: ${appState.user!.displayName}");
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Transaction Group List'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            appState.signOut();
                            Navigator.pop(context);
                          },
                          child: Text('Logout'),
                        )
                      ]
                    )
                  );
                },
              ),
              // IconButton(
              //   icon: Icon(Icons.refresh),
              //   onPressed: () {
              //     appState.clearData();
              //   },
              // ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  _showAddTransactionGroupDialog(context, appState);
                }
              )
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildTransactionGroupsList(appState)
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  children: [
                    // SizedBox(width: 10),
                    // ElevatedButton(
                    //   child: Text('Calculate'),
                    //   onPressed: () {
                    //     if (appState.participants.isEmpty) {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         SnackBar(
                    //           content: Text('Add participants first.'),
                    //         ),
                    //       );
                    //       return;
                    //     }
                    //     appState.calculateSettlements();
                    //   },
                    // ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // _showAddTransactionGroupDialog(context, appState);
              _showJoinTransactionGroupDialog(context, appState);
            },
            child: Text('Join'),
          ),
        );
      },
    );
  }

  void _showAddTransactionGroupDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (context) => AddTransactionGroupDialog(appState: appState),
    );
  }

  void _showJoinTransactionGroupDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (context) => JoinTransactionGroupDialog(appState: appState),
    );
  }


  Widget _buildTransactionGroupsList(AppState appState) {
    return appState.transactionGroups.isEmpty
        ? Center(child: Text('No transaction groups added.'))
        : ListView.builder(
          itemCount: appState.transactionGroups.length,
          itemBuilder: (context, index) {
            final transactionGroup = appState.transactionGroups[index];
            return ListTile(
              title: Text(
                transactionGroup.groupName,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text('Created by: ${transactionGroup.ownerName}'),
                  FutureBuilder<String>(
                    future: appState.fetchUserName(transactionGroup.owner),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading owner...');
                      } else if (snapshot.hasError) {
                        return Text('Error loading owner');
                      } else {
                        return Text('Created by: ${snapshot.data}');
                      }
                    },
                  ),
                  FutureBuilder<List<String>>(
                    future: appState.fetchUserNames(transactionGroup.sharedWith),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading shared users...');
                      } else if (snapshot.hasError) {
                        return Text('Error loading shared users');
                      } else {
                        final sharedNames = snapshot.data!.join(', ');
                        return Text('Shared with: $sharedNames');
                      }
                    },
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  appState.removeTransactionGroup(transactionGroup.id!);
                }
              ),
              onTap: () {
                appState.updateCurrentTransactionGroup(transactionGroup);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TransactionGroupScreen()),
                );
              }
            );
          }
        );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
