// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitter/models/transaction_group.dart';
import 'package:splitter/screens/sign_in_screen.dart';
import '../providers/app_state.dart';
import '../screens/transaction_group_screen.dart';
import '../providers/utils.dart';
import '../screens/add_transaction_group_dialog.dart';

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
                icon: Icon(Icons.refresh),
                onPressed: () {
                  appState.clearData();
                },
              ),
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
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Join Transaction Group'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Enter Invite Token"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context); // Capture before async call
                String inviteToken = _controller.text.trim();
                if (inviteToken.isNotEmpty) {
                  bool success = await appState.joinTransactionGroup(inviteToken);
                  if (success) {
                    Navigator.pop(context);
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Invalid invite token'),
                      ),
                    );
                  }
                }
              },
              child: Text('Join'),
            ),
          ],
        );
      },
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
                capitalize(transactionGroup.groupName),
              ),
              subtitle: Text(
                'Created by: ${transactionGroup.owner}'
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
