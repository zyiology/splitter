// lib/screens/manage_currency_rates_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/currency_rate.dart';
import '../main.dart';

class ManageCurrencyRatesScreen extends StatefulWidget {
  @override
  _ManageCurrencyRatesScreenState createState() => _ManageCurrencyRatesScreenState();
}

class _ManageCurrencyRatesScreenState extends State<ManageCurrencyRatesScreen> {
   // To manage TextEditingControllers efficiently, use a Map to store controllers by currency ID
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    // Dispose all controllers when the widget is disposed
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Currency Rates'),
      ),
      body: ListView.builder(
        itemCount: appState.currencyRates.length,
        itemBuilder: (context, index) {
          final currency = appState.currencyRates[index];

          // Initialize controller if not already done
          _controllers.putIfAbsent(
              currency.id!,
              () => TextEditingController(text: currency.rate.toString()));

          final controller = _controllers[currency.id]!;

          return ListTile(
            title: Text(currency.symbol),
            trailing: SizedBox(
              width: 150,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Rate',
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onSubmitted: (value) async {
                        double? rate = double.tryParse(value);
                        if (rate != null) {
                          bool success =
                              await appState.updateCurrencyRate(currency.id!, rate);
                          if (!success) {
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to update rate for ${currency.symbol}')),
                            );
                          }
                        } else {
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Invalid rate for ${currency.symbol}')),
                          );
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDeletion(context, currency);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Currency',
        onPressed: () {
          _showAddCurrencyDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeletion(BuildContext context, CurrencyRate currency) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Currency"),
          content: Text(
              "Are you sure you want to delete ${currency.symbol}? This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _removeCurrency(currency.id!, currency.symbol);
    }
  }

  Future<void> _removeCurrency(String id, String symbol) async {
    final appState = Provider.of<AppState>(context, listen: false);

    bool success = await appState.removeCurrencyRate(id);
    
    if (success) {

      // Optionally, show a success message
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$symbol has been removed.')),
      );
      // Dispose the controller as it's no longer needed
      if (_controllers.containsKey(id)) {
        _controllers[id]!.dispose();
        _controllers.remove(id);
      }
    } else {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
            content: Text(
                '$symbol is currently used in transactions and cannot be removed.')),
      );
    }
  }


  void _showAddCurrencyDialog(BuildContext context) {
    final symbolController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Currency"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: symbolController,
                decoration: InputDecoration(labelText: 'Currency Symbol'),
              ),
              TextField(
                controller: rateController,
                decoration: InputDecoration(labelText: 'Exchange Rate'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Add"),
              onPressed: () {
                String symbol = symbolController.text.trim();
                double? rate = double.tryParse(rateController.text.trim());

                if (symbol.isEmpty || rate == null) {
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text('Invalid input')),
                  );
                  return;
                }

                Provider.of<AppState>(context, listen: false)
                    .addCurrencyRate(symbol, rate);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
