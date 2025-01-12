# Splitter

A mobile app for tracking and splitting group expenses. Perfect for trips, shared housing, or any situation where multiple people need to track shared costs.

## Features
- **Transaction Groups**: Create groups for different events or situations (e.g., vacation trips, shared housing)
- **Multi-participant Support**: Add participants to your groups - they don't need to install the app
- **Multi-currency Support**: Handle transactions in different currencies within the same group
- **Real-time Sync**: All changes are synchronized instantly between group members
- **Group Sharing**: Join groups easily using invite-IDs

## Installation
Download the latest APK from the [Releases](link-to-releases) page.

For beta testers:
1. Enable "Install from Unknown Sources" in your Android settings
2. Download and install the APK
3. Launch the app and create an account to get started

## Usage Guide
### Creating a Transaction Group
1. Tap the "+" button on the home screen
2. Enter a name for your group
3. Enter a default currency

### Joining a Group
1. Get the invite-ID from a group member
2. Enter the ID on the home screen's "Join Group" section

### Recording Transactions
1. Add participants
2. Add additional currencies beyond the default
3. Add transactions, using the participants and currencies
4. Press the settlements button on the top right to see what the balance of the current transactions is
5. Press the share icon to get a invite-id for the transaction group

## Technical Details
- Built with Flutter
- Uses Firebase for backend services
- Minimum Android version: [6 / SDK level 23]

## Development
### Prerequisites
- Flutter SDK
- Android Studio / VS Code
- Firebase project setup

### Setup
1. Clone the repository
2. [Firebase setup instructions]
3. [Other setup steps...]

### Building
[Build instructions...]

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

### Reporting Issues
When reporting issues, please include:
- Your device model and Android version
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots if applicable

## License

This project is licensed under the GNU General Public License v3.0.
Third-Party Licenses

This project uses several open-source libraries with compatible licenses:

    Firebase Libraries: Licensed under the Apache License 2.0. For details, visit Apache License 2.0.
    Provider, Cupertino Icons, UUID: Licensed under the MIT License.
    Flutter Framework: Licensed under the BSD 3-Clause License. For details, visit BSD 3-Clause License.