// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'add_transaction_screen.dart';
import 'manage_participants_screen.dart';
import 'manage_currency_rates_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Transaction Settlement'),
            actions: [
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
                child: appState.settlements.isEmpty
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
                      ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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
                    ElevatedButton(
                      child: Text('Calculate'),
                      onPressed: () {
                        if (appState.participants.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Add participants first.'),
                            ),
                          );
                          return;
                        }
                        appState.calculateSettlements();
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

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
