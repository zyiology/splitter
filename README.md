# splitter

TODO:
- modify sharing allow use of deep links/app links instead of only sharing the invite-id

maybe:
- stop the copy thing from popping up?
- figure out how to debug and see variable values
- make it ignore corrupted firestore stuff
--handle this exception? FirebaseException: An internal error has occurred. [ API key expired. Please renew the API key. ].
- user profile pic?

lessons:
removing google-services.json was annoying... have to git rm --cached and push to make sure no protected commit HEAD, then run bfg to clean the repo history... then rerun flutterfire configure to prevent dupe app...

downgraded addUserToGroup function to v1, since only v1 supports onUserCreate
get Error: Cannot set CPU on the functions addUserToGroup because they are GCF gen 1
need to delete old function in console first

SHA1 certificates to match
IN FIREBASE CONSOLE PROJECT SETTINGS
IN CREDENTIALS OAUTH2
IN API KEY

Commands for building stuff
keytool -genkey -v -keystore ~/key.jks -alias key -keyalg RSA -keysize 2048 -validity 10000

keytool -list -v -keystore ~/key.jks -alias key

flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

flutter build apk --release