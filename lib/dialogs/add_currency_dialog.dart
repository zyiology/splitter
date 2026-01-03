// lib/widgets/add_currency_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/currency_rate.dart';

class AddCurrencyDialog extends StatefulWidget {
  @override
  _AddCurrencyDialogState createState() => _AddCurrencyDialogState();
}

class _AddCurrencyDialogState extends State<AddCurrencyDialog> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _symbolController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _addCurrency() async {
    String symbol = _symbolController.text.trim();
    double? rate = double.tryParse(_rateController.text.trim());

    if (symbol.isEmpty || rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid input')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    CurrencyRate? currRate = await Provider.of<AppState>(context, listen: false)
        .addCurrencyRate(symbol, rate);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (currRate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${currRate.symbol} has been added.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add currency. Check if symbol already exists.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addCurrency,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text("Add"),
        ),
      ],
    );
  }
}
