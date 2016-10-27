# Flybitslite-iOS

Note: Xcode Version 8.0 (8A218a) was used to create this sample.

Building the sample:

1. Get an API key from Flybits Inc.
2. Set the API key in 'AppDelegate.swift' and then remove the 'assert' statement on line 27 and 28.
3. Change the app bundle identfier i.e., com.mycompany.flybitslite_sample
4. Fix certificate issues (if any)
5. Build and run


To test APNs push:
1. You have to create an app id on developer.apple.com
2. Enable push for the app id, and generate a certifiate and download it to your keychain
3. Export the certificate from your keychain (.p12)

 Note: In keychain, certificates will be named as:
  Development:  Apple Development IOS Push Services: com.mycompany.flybitslite_sample
  Production:   Apple Push Services: com.mycompany.flybitslite_sample

4. Upload the exported certificate (.p12 file) in developer.flybits.com under `APNs settings` for the active project.
5. Test sending push message using 'Notification' moment or 'Push Portal'.
