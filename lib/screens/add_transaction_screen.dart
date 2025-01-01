// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _amount;
  String? _currency;
  String? _payer;
  List<String> _selectedPayees = [];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currencies = appState.currencyRates.map((c) => c.symbol).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: appState.participants.isEmpty
            ? Center(child: Text('No participants available. Add participants first.'))
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _amount = double.parse(value!);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Currency'),
                      items: currencies
                          .map((symbol) => DropdownMenuItem(
                                child: Text(symbol),
                                value: symbol,
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _currency = value;
                        });
                      },
                      validator: (value) => value == null ? 'Select currency' : null,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Payer'),
                      items: appState.participants
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _payer = value;
                        });
                      },
                      validator: (value) => value == null ? 'Select payer' : null,
                    ),
                    SizedBox(height: 10),
                    Text('Payees'),
                    ...appState.participants.map((p) {
                      return CheckboxListTile(
                        title: Text(p),
                        value: _selectedPayees.contains(p),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedPayees.add(p);
                            } else {
                              _selectedPayees.remove(p);
                            }
                          });
                        },
                      );
                    }).toList(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Add Transaction'),
                      onPressed: _addTransactionHandler,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);


  Future<void> _addTransactionHandler() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_selectedPayees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select at least one payee.')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final appState = Provider.of<AppState>(context, listen: false);
      final transaction = SplitterTransaction(
        amount: _amount!,
        payer: _payer!,
        payees: _selectedPayees,
        currency: _currency!,
      );

      // Change homescreen to also show transactions instead of settlements
      appState.toggleView(true);

      try {
        final transactionId = await appState.addTransaction(transaction);
        // Optionally, you can use the transactionId for further actions

        // Pop loading indicator
        Navigator.of(context, rootNavigator: true).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction added successfully!')),
        );

        // Pop the AddTransactionScreen
        Navigator.pop(context);
      } catch (error) {
        // Pop loading indicator
        Navigator.of(context, rootNavigator: true).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      }
    }
  }
}
