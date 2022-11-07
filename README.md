# Tool to obtain distribution certificate and provisioning profiles required for the new app and its extensions

## What is it doing, step by step:
* Getting app details
  * the app name
  * the app bundle identifier
  * the Apple Developer account team id related to this app
* Getting the user account credentials
  * apple id of the Apple Developer program with App Manager role `(at least, and 2fa should be enabled on the provided apple id)`
  * password (not stored anywhere)
* Performing login to provided user account 
  * if there is 1 attached phone number for 2fa, entering the received code to continue, in case there are multiple authorized phone numbers, selecting the one to be used with the login
* Checking if there are active Distribution Certificates on this account, 
  * printing the details of ones that are active
  * in case none of them exists on the mac keychain, asking to create a new one, otherwise using the one already in keychain. 
    * if authorizing to create, creating new certificate and saving its p12 file as \<id\>.p12 and password as \<id\>.txt to the output folder
* Checking if the app instance with provided bundle identifier is available in Developer portal
  * creating new one with the provided name and bundle identifier if not exists
  * skipping to next step if exists
* Checking if the `notification content extension` app instance with provided `<bundle identifier>.NotificationContentExtension` is available in Developer portal
  * creating new one with the `<provided name> - NotificationContentExtension` and bundle identifier if not exists
  * skipping to next step if exists
* Checking if the `notification service extension` app instance with provided `<bundle identifier>.NotificationServiceExtension` is available in Developer portal
  * creating new one with the `<provided name> - NotificationServiceExtension` and bundle identifier if not exists
  * skipping to next step if exists
* Checking if the `app widget extension` app instance with provided `<bundle identifier>.AppWidgetExtension` is available in Developer portal
  * creating new one with the `<provided name> - AppWidgetExtension` and bundle identifier if not exists
  * skipping to next step if exists
* Creating provisioning profiles
  * app provisioning profile
  * notification content extension profile
  * notification service extension profile
  * widget extension profile
  * deleting expirted profiles if needed
* Checking if the app instance with provided bundle identifier is available in AppStoreConnect
  * creating new one with the provided name and bundle identifier if not exists for both iOS and tvOS
  * skipping to next step if exists
  
  
## Steps to make it work on mac:

1.  Install bundler:
`gem install bundler`


2. Clone the repo
  * find location on disk to clone the repo to
  * open Terminal app
  * type `cd ` and drag and drop parent folder to it, press right arrow and enter to switch to the folder
  
    https://user-images.githubusercontent.com/3462044/200165080-28280e04-3504-427e-93ce-19eac93ed2d2.mov

  * call `git clone https://github.com/applicaster/apple-prepare-app.git`
    * (or `git clone git@github.com:applicaster/apple-prepare-app.git` with ssh)
  * switch to newly created folder `apple-prepare-app` (use `cd apple-prepare-app`)
    
    https://user-images.githubusercontent.com/3462044/200165259-905f80d7-d249-416e-82fd-172e28ce09ff.mov

4. Run `bundle update` to update dependencies
    
    https://user-images.githubusercontent.com/3462044/200165343-232c7dad-3a1c-44bc-a59b-9e8e48488080.mov


Execution step:
* Run `bundle exec fastlane prepare` to perform the action
