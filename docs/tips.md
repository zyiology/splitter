# Tips

## Provider and Dialogs

- Dialogs can read `AppState` with `context.read<AppState>()` if they are shown
  from a `BuildContext` that lives under the `ChangeNotifierProvider<AppState>`.
- If a dialog is shown from a context outside the provider tree, Provider lookup
  will fail. In that case, pass `AppState` into the dialog or wrap the caller
  with the provider.
- In this app, dialogs opened from `HomeScreen` are safe to read `AppState`
  directly because `HomeScreen` is built under the provider.
