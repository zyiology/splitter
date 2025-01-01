// lib/screens/add_transaction_group_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitter/models/currency_rate.dart';
import '../providers/app_state.dart';
import '../models/transaction_group.dart';
import '../providers/utils.dart';
import '../screens/transaction_group_screen.dart';

class AddTransactionGroupDialog extends StatefulWidget {
  final AppState appState;

  AddTransactionGroupDialog({required this.appState});

  @override
  _AddTransactionGroupDialogState createState() => _AddTransactionGroupDialogState();
}

class _AddTransactionGroupDialogState extends State<AddTransactionGroupDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _addGroup() async {
    String groupName = _controller.text.trim();
    String currency = _currencyController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group name cannot be empty.')),
      );
      return;
    }
    if (currency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Currency cannot be empty.')),
      );
      return;
    }

    // More aggressive keyboard dismissal
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    setState(() {
      isLoading = true;
    });

    try {
      SplitterTransactionGroup group = SplitterTransactionGroup(
        owner: widget.appState.user!.uid,
        ownerName: widget.appState.user!.displayName!,
        sharedWith: [widget.appState.user!.uid],
        groupName: groupName,
        createdAt: DateTime.now(),
        inviteToken: generateInviteToken(),
      );

      print('prepared transaction group');

      // Perform the async operation
      SplitterTransactionGroup addedGroup = await widget.appState.addTransactionGroup(group);
      print('added transaction group');

      // add the currency to the currency rates and update the current transaction group
      CurrencyRate currRate = await widget.appState.addCurrencyRate(currency, 1.0, groupId:addedGroup.id);
      print('added currency rate');
      addedGroup = addedGroup.copyWith(defaultCurrencyId: currRate.id);
      
      // update the firestore document with the currency id
      await widget.appState.updateTransactionGroup(addedGroup);

      // After the await, check if the widget is still mounted
      if (!mounted) return;

      // Update the current transaction group
      widget.appState.updateCurrentTransactionGroup(addedGroup);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionGroupScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Transaction Group'),
      content: isLoading
          ? SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Group Name",
                  border: OutlineInputBorder(),
                ),
              ),
              // Spacing between fields
              SizedBox(height: 16),
              TextField(
                controller: _currencyController,
                decoration: InputDecoration(
                  hintText: "Default Currency (e.g. USD)",
                  border: OutlineInputBorder(),
                ),
              )
            ]
          ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _addGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text('Add'),
        ),
      ],
    );
  }
}
