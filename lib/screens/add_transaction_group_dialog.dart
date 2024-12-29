import 'package:flutter/material.dart';
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
  bool isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addGroup() async {
    String groupName = _controller.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group name cannot be empty.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SplitterTransactionGroup group = SplitterTransactionGroup(
        owner: widget.appState.user!.uid,
        sharedWith: [widget.appState.user!.uid],
        groupName: groupName,
        createdAt: DateTime.now(),
        inviteToken: generateInviteToken(),
      );

      // Perform the async operation
      SplitterTransactionGroup addedGroup = await widget.appState.addTransactionGroup(group);

      // After the await, check if the widget is still mounted
      if (!mounted) return;

      // Update the current transaction group
      widget.appState.updateCurrentTransactionGroup(addedGroup);

      Navigator.of(context).pop(); // Close the dialog

      // Navigate to TransactionGroupScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransactionGroupScreen()),
      );
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
          : TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Group Name",
                border: OutlineInputBorder(),
              ),
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
