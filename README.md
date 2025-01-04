# splitter

TODO:
- modify sharing allow use of deep links/app links instead of only sharing the invite-id
-show loading while joining tg
-show who group is shared with somewhere
-make currency/payer autopopulate with first person
-force minimum one payee

maybe
- stop the copy thing from popping up?
- figure out how to debug and see variable values
- make it ignore corrupted firestore stuff
- handle this exception? FirebaseException: An internal error has occurred. [ API key expired. Please renew the API key. ].

removing google-services.json was annoying... have to git rm --cached and push to make sure no protected commit HEAD, then run bfg to clean the repo history... then rerun flutterfire configure to prevent dupe app...