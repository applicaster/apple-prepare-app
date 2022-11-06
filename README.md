# Tool to obtain distribution certificate and provisioning profiles required for the new app and its extensions

Steps to make it work:

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
