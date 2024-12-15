// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitter/screens/sign_in_screen.dart';
import '../providers/app_state.dart';
import 'add_transaction_screen.dart';
import 'manage_participants_screen.dart';
import 'manage_currency_rates_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        print("HomeScreen consumer building, isLoading: ${appState.isLoading}");
        print("user: ${appState.user?.uid}");
        print("participants: ${appState.participants.length}");

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
            title: Text('Transaction Settlement'),
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
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  appState.clearData();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: appState.showTransactions
                    ? _buildTransactionsList(appState)
                    : _buildSettlementsList(appState)
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add Transaction'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.people),
                      label: Text('Manage Participants'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageParticipantsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.currency_exchange),
                      label: Text('Currency Rates'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageCurrencyRatesScreen(),
                          ),
                        );
                      },
                    ),
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
                '${capitalize(transaction.payer)} paid ${transaction.currency}${transaction.amount.toStringAsFixed(2)} ',
              ),
              subtitle: Text(
                'Payees: ${transaction.payees.map(capitalize).join(', ')}'
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
                  '${capitalize(settlement.debtor)} owes ${capitalize(settlement.creditor)} \$${settlement.amount.toStringAsFixed(2)}',
                ),
              );
            },
          );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
