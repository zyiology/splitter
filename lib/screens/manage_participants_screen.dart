// lib/screens/manage_participants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ManageParticipantsScreen extends StatefulWidget {
  @override
  _ManageParticipantsScreenState createState() => _ManageParticipantsScreenState();
}

class _ManageParticipantsScreenState extends State<ManageParticipantsScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Participants'),
      ),
      body: Column(
        children: [
          ListTile(
            title: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New Participant',
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                String name = _controller.text.trim().toLowerCase();
                if (name.isNotEmpty && !appState.participants.any((p) => p.name == name)) {
                  appState.addParticipant(name);
                  _controller.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid or duplicate name')),
                  );
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: appState.participants.length,
              itemBuilder: (context, index) {
                final participant = appState.participants[index];
                return ListTile(
                  title: Text(participant.name),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      print('going to delete $participant');
                      appState.removeParticipant(participant.id!);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
