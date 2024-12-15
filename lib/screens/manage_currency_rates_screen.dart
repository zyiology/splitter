// lib/screens/manage_currency_rates_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/currency_rate.dart';

class ManageCurrencyRatesScreen extends StatefulWidget {
  @override
  _ManageCurrencyRatesScreenState createState() => _ManageCurrencyRatesScreenState();
}

class _ManageCurrencyRatesScreenState extends State<ManageCurrencyRatesScreen> {
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
          final controller = TextEditingController(text: currency.rate.toString());

          return ListTile(
            title: Text(currency.symbol),
            trailing: Container(
              width: 100,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Rate',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (value) {
                  double? rate = double.tryParse(value);
                  if (rate != null) {
                    appState.setCurrencyRate(currency.symbol, rate);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid rate for ${currency.symbol}')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Add Currency',
        onPressed: () {
          _showAddCurrencyDialog(context);
        },
      ),
    );
  }

  void _showAddCurrencyDialog(BuildContext context) {
    final _symbolController = TextEditingController();
    final _rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Currency"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _symbolController,
                decoration: InputDecoration(labelText: 'Currency Symbol'),
              ),
              TextField(
                controller: _rateController,
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
                String symbol = _symbolController.text.trim();
                double? rate = double.tryParse(_rateController.text.trim());

                if (symbol.isEmpty || rate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid input')),
                  );
                  return;
                }

                Provider.of<AppState>(context, listen: false)
                    .setCurrencyRate(symbol, rate);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
