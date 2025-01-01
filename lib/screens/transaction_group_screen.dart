// lib/screens/transaction_group_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.share),
                      label: Text('Share'),
                      onPressed: () async {
                        // copy the transactiongroup inviteToken to the clipboard
                        final inviteToken = appState.currentTransactionGroup!.inviteToken;
                        final messenger = ScaffoldMessenger.of(context); // Capture before async call
                        try {
                          await Clipboard.setData(ClipboardData(text: inviteToken));
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Invite token copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to copy invite token'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
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

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
