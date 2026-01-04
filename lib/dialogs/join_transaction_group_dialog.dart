import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../utils/input_utils.dart';

class JoinTransactionGroupDialog extends StatefulWidget {
  final AppState appState;

  const JoinTransactionGroupDialog({super.key, required this.appState});

  @override
  State<JoinTransactionGroupDialog> createState() =>
      _JoinTransactionGroupDialogState();
}

class _JoinTransactionGroupDialogState
    extends State<JoinTransactionGroupDialog> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  void _joinGroup() async {
    setState(() {
      isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    String inviteToken = _controller.text.trim();
    // sanitize the inputs
    inviteToken = InputUtils.sanitizeString(inviteToken);

    if (inviteToken.isNotEmpty) {
      bool success = await widget.appState.joinTransactionGroup(inviteToken);
      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
      } else {
        setState(() {
          isLoading = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Invalid invite token'),
          ),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Please enter a token'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Join Transaction Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Enter Invite Token"),
            enabled: !isLoading,
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : _joinGroup,
          child: Text('Join'),
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
