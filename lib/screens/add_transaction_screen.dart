// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../utils/input_utils.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _amount;
  String? _currency;
  String? _payer;
  final List<String> _selectedPayees = [];
  String? _description;

  // state variables for tax and service charge
  bool _includeTax = false;
  bool _includeServiceCharge = false;
  double? _tax;
  double? _serviceCharge;
  
  @override
  void initState() {
    super.initState();
    // Delay accessing context to after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      setState(() {
        _tax = appState.currentTransactionGroup?.defaultTax;
        _serviceCharge = appState.currentTransactionGroup?.defaultServiceCharge;

        // Initialize currency
        final defaultCurrencyId = appState.currentTransactionGroup?.defaultCurrencyId;
        _currency = appState.currencyRates
            .firstWhere(
              (c) => c.id == defaultCurrencyId,
              orElse: () => appState.currencyRates.first,
            )
            .symbol;

        // Initialize payer
        _payer = appState.participants.isNotEmpty ? appState.participants.first.name : null;
      });
    });
    // final appState = Provider.of<AppState>(context, listen: false);
    // _tax = appState.currentTransactionGroup?.defaultTax;
    // _serviceCharge = appState.currentTransactionGroup?.defaultServiceCharge;
  }

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
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Description (optional)'),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      onSaved: (value) {
                        if (value == null || value.trim().isEmpty) {
                          _description = null;
                        } else {
                          _description = value.trim();
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Currency'),
                      initialValue: _currency,
                      items: currencies
                          .map((symbol) => DropdownMenuItem(
                                value: symbol,
                                child: Text(symbol),
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
                      initialValue: _payer,
                      items: appState.participants
                          .map((p) => DropdownMenuItem(
                                value: p.name,
                                child: Text(p.name),
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
                        title: Text(p.name),
                        value: _selectedPayees.contains(p.name),
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedPayees.add(p.name);
                            } else {
                              _selectedPayees.remove(p.name);
                            }
                          });
                        },
                      );
                    }),
                    SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text('Include Tax'),
                      value: _includeTax,
                      onChanged: (bool? value) {
                        setState(() {
                          _includeTax = value ?? false;
                          if (_includeTax && _tax == null) {
                            _tax = appState.currentTransactionGroup?.defaultTax;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_includeTax)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Tax (%)'),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          initialValue: _tax?.toString(),
                          validator: (value) {
                            if (_includeTax) {
                              if (value == null || value.isEmpty) {
                                return 'Enter tax percentage';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                            }
                            return null;
                          },
                          onSaved: (value) {
                            if (_includeTax) {
                              _tax = double.parse(value!);
                            }
                          },
                        ),
                      ),
                    SizedBox(height: 10),

                    // Service charge checkbox and textfield
                    CheckboxListTile(
                      title: Text('Include Service Charge'),
                      value: _includeServiceCharge,
                      onChanged: (bool? value) {
                        setState(() {
                          _includeServiceCharge = value ?? false;
                          if (_includeServiceCharge && _serviceCharge == null) {
                            _serviceCharge = appState.currentTransactionGroup?.defaultServiceCharge;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_includeServiceCharge)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          decoration: InputDecoration(labelText: 'Service Charge (%)'),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          initialValue: _serviceCharge?.toString(),
                          validator: (value) {
                            if (_includeServiceCharge) {
                              if (value == null || value.isEmpty) {
                                return 'Enter service charge percentage';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                            }
                            return null;
                          },
                          onSaved: (value) {
                            if (_includeServiceCharge) {
                              _serviceCharge = double.parse(value!);
                            }
                          },
                        ),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addTransactionHandler,
                      child: Text('Add Transaction'),
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

      // Calculate the adjusted amount
      double adjustedAmount = _amount!;

      if (_includeTax && _tax != null) {
        adjustedAmount *= (1 + _tax! / 100);
      }

      if (_includeServiceCharge && _serviceCharge != null) {
        adjustedAmount *= (1 + _serviceCharge! / 100);
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // sanitize inputs
      _payer = InputUtils.sanitizeString(_payer!);
      _selectedPayees
          .replaceRange(0, _selectedPayees.length, _selectedPayees.map((payee) => InputUtils.sanitizeString(payee)).toList());
      _currency = InputUtils.sanitizeString(_currency!);
      if (_description != null) {
        _description = InputUtils.sanitizeString(_description!);
      }
      // print('adding transaction. payer: $_payer, payees: $_selectedPayees, currency: $_currency');

      final appState = Provider.of<AppState>(context, listen: false);
      final transaction = SplitterTransaction(
        amount: adjustedAmount,
        payer: _payer!,
        payees: _selectedPayees,
        currencySymbol: _currency!,
        description: _description,
      );

      // Change homescreen to also show transactions instead of settlements
      appState.toggleView(true);

      try {
        await appState.addTransaction(transaction);

        // Check if the widget is still mounted before proceeding
        if (!mounted) return;

        // Pop loading indicator
        Navigator.of(context, rootNavigator: true).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction added successfully!')),
        );

        // Pop the AddTransactionScreen
        Navigator.pop(context);
      } catch (error) {
        if (!mounted) return;
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
