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



Screenshots:

Menu:
![alt text](https://cloud.githubusercontent.com/assets/17835432/19780758/56ae72b4-9c54-11e6-878d-111a35da4795.png "Side menu")


Zones page:
![alt text](https://cloud.githubusercontent.com/assets/17835432/19780759/56b28c0a-9c54-11e6-9f0b-606b5d0ec52c.png "List of zones")


Moments page:
![alt text](https://cloud.githubusercontent.com/assets/17835432/19780760/56b436f4-9c54-11e6-81a8-976a392a6e09.png "Grid of moments of 'Demo Zone'")

