// lib/screens/transaction_group_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:splitter/screens/home_screen.dart';
import '../providers/app_state.dart';
import 'add_transaction_screen.dart';
import 'manage_participants_screen.dart';
import 'manage_currency_rates_screen.dart';

class TransactionGroupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {

        if (appState.currentTransactionGroup == null) {
          return HomeScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(appState.currentTransactionGroup!.groupName),
            actions: [
              IconButton(
                icon: Icon(appState.showTransactions ? Icons.receipt_long : Icons.calculate),
                tooltip: appState.showTransactions ? 'Show Settlements' : 'Show Transactions',
                onPressed: () {
                  appState.toggleView();
                  if (!appState.showTransactions) {
                    appState.calculateSettlements();
                  }
                }
              ),
              // IconButton(
              //   icon: Icon(Icons.refresh),
              //   onPressed: () {
              //     appState.clearData();
              //   },
              // ),
            ],
          ),
          body: appState.showTransactions
              ? _buildTransactionsList(appState)
              : _buildSettlementsList(appState),
          bottomNavigationBar: _buildBottomBar(context, appState),
        );
      },
    );
  }

  Widget _buildTransactionsList(AppState appState) {
    return appState.transactions.isEmpty
        ? Center(child: Text('No transactions added.'))
        : ListView.builder(
          itemCount: appState.transactions.length,
          itemBuilder: (context, index) {
            final transaction = appState.transactions[index];
            return ListTile(
              title: Text(
                '${transaction.payer} paid ${transaction.currencySymbol}${transaction.amount.toStringAsFixed(2)} ',
              ),
              subtitle: Text(
                'Payees: ${transaction.payees.join(', ')}'
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  appState.removeTransaction(transaction.id!);
                }
              ),
            );
          }
        );
  }

  Widget _buildSettlementsList(AppState appState) {
    return appState.settlements.isEmpty
        ? Center(child: Text('No settlements calculated.'))
        : ListView.builder(
            itemCount: appState.settlements.length,
            itemBuilder: (context, index) {
              final settlement = appState.settlements[index];
              return ListTile(
                title: Text(
                  '${settlement.debtor} owes ${settlement.creditor} ${appState.getCurrentTransactionCurrencySymbol()}${settlement.amount.toStringAsFixed(2)}',
                ),
              );
            },
          );
  }

  Widget _buildBottomBar(BuildContext context, AppState appState) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(), // Optional: if using FAB
      notchMargin: 6.0, // Optional: if using FAB
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Add Transaction Button
            IconButton(
              icon: Icon(Icons.add),
              tooltip: 'Add Transaction',
              onPressed: () async {
                // if no participants, show an alert dialog
                if (appState.participants.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('No participants'),
                        content: Text('Please add participants before adding a transaction.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                // Navigate to AddTransactionScreen and await result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(),
                  ),
                );

                // Handle the result and show SnackBar using the parent ScaffoldMessenger
                if (result == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transaction added successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (result == 'error') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add transaction.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            // Manage Participants Button
            IconButton(
              icon: Icon(Icons.people),
              tooltip: 'Manage Participants',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageParticipantsScreen(),
                  ),
                );
              },
            ),
            // Manage Currency Rates Button
            IconButton(
              icon: Icon(Icons.currency_exchange),
              tooltip: 'Currency Rates',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageCurrencyRatesScreen(),
                  ),
                );
              },
            ),
            // Share Button
            IconButton(
              icon: Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context); // Capture before async call
                final inviteToken = appState.currentTransactionGroup?.inviteToken;
                if (inviteToken == null || inviteToken.isEmpty) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Invite token is not available.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                String appLink = "https://splitter-2e1ae.web.app/join?token=$inviteToken";
                try {
                  await Share.share('Join my transaction group on Splitter! $appLink');
                  // Optionally, if you still want a SnackBar confirmation:
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Share dialog initiated.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to initiate share: $error'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBottomBar(BuildContext context, AppState appState) {
  //   return Container(
  //     padding: const EdgeInsets.all(8.0),
  //     color: Theme.of(context).scaffoldBackgroundColor,
  //     child: SingleChildScrollView(
  //       scrollDirection: Axis.horizontal,
  //       child: Row(
  //         children: [
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.add),
  //             label: Text('Add Transaction'),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => AddTransactionScreen(),
  //                 ),
  //               );
  //             },
  //           ),
  //           SizedBox(width: 10),
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.people),
  //             label: Text('Manage Participants'),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => ManageParticipantsScreen(),
  //                 ),
  //               );
  //             },
  //           ),
  //           SizedBox(width: 10),
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.currency_exchange),
  //             label: Text('Currency Rates'),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => ManageCurrencyRatesScreen(),
  //                 ),
  //               );
  //             },
  //           ),
  //           SizedBox(width: 10),
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.share),
  //             label: Text('Share'),
  //             onPressed: () async {
  //               // copy the transactiongroup inviteToken to the clipboard
  //               final inviteToken = appState.currentTransactionGroup!.inviteToken;
  //               final messenger = ScaffoldMessenger.of(context); // Capture before async call
  //               try {
  //                 await Clipboard.setData(ClipboardData(text: inviteToken));
  //                 messenger.showSnackBar(
  //                   SnackBar(
  //                     content: Text('Invite token copied to clipboard'),
  //                     duration: Duration(seconds: 2),
  //                   ),
  //                 );
  //               } catch (error) {
  //                 messenger.showSnackBar(
  //                   SnackBar(
  //                     content: Text('Failed to copy invite token'),
  //                     duration: Duration(seconds: 2),
  //                   ),
  //                 );
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
