---
layout: post
title:  "Continuous Integration and Deployment of Ionic mobile applications with Gitlab CI and Fastlane"
comments: true
categories: gitlab
sharing:
  twitter: Continuous Integration and Deployment of Ionic mobile applications with \@gitlab CI and Fastlane
---

# Continuous Integration/Deployment for mobile

The mobile software development (aka Apps Development) became more and more specific in this period, as far as became an entire department with (sometimes) hierachy and open positions. This brought the need of common software development pratices like Continuous Integration and Continuous Deployment.

The continuous integration is pretty standard with tests for the "business logic" and many others, like end to end tests with a simulated backend and so on and so forth.
The continuous deployment, instead, consist in the distribution of an update through all the platform (iOS, Android, and sometimes Windows) stores. 

So far everthing seems a standard procedure, but among the jungle of mobile development frameworks (ionic, flutter, native development) is not! If the test part could be easily made using one of the test frameworks for the selected platform (in combination with the development framework), btw good luck with that, the deployment part requires some manual procedures and validation triggers.  
Also to deploy in "production" the applications you have to produce a lot of legal documentation (GDPR), and beyond that the developers have to produce screenshots of the application on a subset of devices.
Fortunately there is a tool which, beyond the legal stuff which is on the company/developer own, there is a tool which cover all the distribution part including screenshots (from the latest releases): Fastlane.

## Fastlane: quick and clean 

[Fastlane](https://fastlane.tools/) is a build tools for fast release of the application, which cover also all the side aspects of application publishing lifecycle and test running (only for apps writtent with the native SDK).  
Fastlane could build your application using traditional build methods, like traditional build method for Android spawning a Gradle daemon or using xcodebuild for iOS, but it also support cross development platform like React Native and Flutter; it supports also Ionic (fortunately!) using third party plugins.  
It could also, with some integrations in terms of software, perform other tasks like screenshots, beta (and also alpha for Android) deployment, and automatic code signing for iOS.

### Get Started with Fastlane

Fastlane requires that you have already created the project(s) for your app on the stores, to do that there are a lot of articles, personally I suggest the one from [themanifest](https://themanifest.com/app-developmenthow-publish-app-google-play-step-step-guide) for Android and a Medium article from the [same author](https://medium.com/@the_manifest/how-to-publish-your-app-on-apples-app-store-in-2018-f76f22a5c33a) for iOS.  
Then after the setup (assuming that you have already installed ``fastlane``) you can move into your app directory (``cd <your-app-directory>``) and then run ``fastlane init``; once done that you have a file called ``Fastfile`` where you can setup your ``lanes`` and another file called ``Appfile``. 
The Appfile contains all your credentials for your app deployment, like keystore (with password), or Apple Store ID for automatic code sign and upload; of course the developer must setup the enviroment, using the guides for [iOS](https://docs.fastlane.tools/getting-started/ios/setup/) and [Android](https://docs.fastlane.tools/getting-started/android/setup/).  
The Fastfile contains all the ``lane`` definitions for the application, they could be "specialized" for each platform (in case of cross platforms). Each lane contains a set of actions, the developer could choose among the native and the one introduced by [plugins](plugin); for instance:

```ruby
lane :playstore do
  gradle(
    task: 'assemble',
    build_type: 'Release'
  )
  upload_to_play_store # Uploads the APK built in the gradle step above and releases it to all production users
end
```
this lane will build your android application and, if everything went fine, upload the APK to play store "in production"