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
this lane will build your android application and, if everything went fine, upload the APK to play store "in production" (where production means the release branch of the store). 

### Fastlane features

Fastlane supports side tasks in mobile app distribution like screenshots for [iOS](https://docs.fastlane.tools/getting-started/ios/screenshots/) and [Android](https://docs.fastlane.tools/getting-started/android/screenshots/), leveraging on emulators for both platforms and other third party software, this procedure could be automated in the FastFile using specific actions.

```ruby
lane :screenshots do
  capture_screenshots
  upload_to_app_store
end
```
For iOS is pretty straight forward because everything is integrated with the development platform, on Android is different, see the [guide](https://docs.fastlane.tools/getting-started/android/screenshots/)

```ruby
lane :screenshots do
  capture_android_screenshots
  upload_to_play_store
end
```
The Android screenshots part is require ``screengrab`` to take screenshots from mobile emulator.  
Fastlane originally was designed to support the entire lifecycle of native-developed mobile applications, in fact the developer could also run tests.  

```ruby
lane :tests do
  gradle(task: "test")
end
```
The above lane show how to run tests on Android, for iOS, instead, it relies on a custom action because the build process is sliced in different tools.

```ruby
lane :tests do
  run_tests(workspace: "Example.xcworkspace",
            devices: ["iPhone 6s", "iPad Air"],
            scheme: "MyAppTests")
end
```
When hybrid/cross development platforms began to become popular, and also to support integration with other horizontal platforms for developers (like slack, hipchat and so on) the Fastlane developers defined a plugin system. Each plugin define custom actions, for instance you can send a message to a slack channel, to be support other platforms or system.  
For instance with the ``gmail`` plugin the developer could send a short report using ``gmail``, but there are a tons of plugins to upload file to slack, or handle firebase, handle version number and so on and so forth.

### Hybrid platforms

Although Fastlane has a huge support to native development, it could handle also a wide variety of hybrid platforms. Platforms like Flutter and React Native are supported using the normal build process, more details [here](https://flutter.dev/docs/deployment/fastlane-cd) for Flutter and [here](https://carloscuesta.me/blog/shipping-react-native-apps-with-fastlane/) for React Native, Xamarin and Ionic/Cordova, instead, are supported through [plugins](https://docs.fastlane.tools/plugins/available-plugins/) (``ionic`` and ``xamarin``).

## Gitlab CI for mobile applications

[Gitlab CI](https://www.google.com/search?q=gitlab+ci&oq=gitlab+ci&aqs=chrome..69i57j69i60l5.2173j0j4&sourceid=chrome&ie=UTF-8) is an embedded CI/CD pipeline tool, it leverage on [runners](https://docs.gitlab.com/runner/) to perform tasks. In order to define a proper pipeline the developer must include a file named ``.gitlab-ci.yml`` in the repository.  
Runner allows to run:
* Multiple jobs concurrently.
* Use multiple tokens with multiple server (even per-project).
* Limit number of concurrent jobs per-token.
Each runner jobs can be run:
* Locally.
* Using Docker containers.
* Using Docker containers and executing job over SSH.
* Using Docker containers with autoscaling on different clouds and virtualization hypervisors.
* Connecting to remote SSH server.
The runner:
* Is written in Go and distributed as single binary without any other requirements.
* Supports Bash, Windows Batch, and Windows PowerShell.
* Works on GNU/Linux, macOS, and Windows (pretty much anywhere you can run Docker).
* Allows customization of the job running environment.
* Automatic configuration reload without restart.
* Easy to use setup with support for Docker, Docker-SSH, Parallels, or SSH running environments.
* Enables caching of Docker containers.
* Easy installation as a service for GNU/Linux, macOS, and Windows.
* Embedded Prometheus metrics HTTP server.  
(credits Gitlab Runner [documentation](https://docs.gitlab.com/runner/#features))

The runner could be configured using the toml file, see gitlab runner advanced configuration [here](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) for details, each runner could be registered multiple times with different providers; for instance a runner on macOS could accept shell tasks (for mobile app build) and also docker build stuff, a windows runner could execute shell tasks and docker (for windows containers) build.

### Gitlab CI files and instructions

The CI pipeline must be defined using a [yaml configuration](https://docs.gitlab.com/ee/ci/yaml/) file, which allows define jobs, prepare the environment, perform other steps after each job or at the end of the pipeline.  
The developer could select which type of runner use in the CI build, using keywords like ``image``, ``services`` or even ``tags`` to give some "hints" to the Gitlab CI job scheduler; if there aren't any feasible runner the job will remain in pending state. The CI jobs could be triggered only for special branches, or for some references (or tags) could perform deployment tasks.  
For instance this is an example (taken from Gitlab [blog](https://about.gitlab.com/2018/10/24/setting-up-gitlab-ci-for-android-projects/)) of CI file for Android:

```yml
image: openjdk:8-jdk

variables:
  ANDROID_COMPILE_SDK: "28"
  ANDROID_BUILD_TOOLS: "28.0.2"
  ANDROID_SDK_TOOLS:   "4333796"

before_script:
  - apt-get --quiet update --yes
  - apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1
  - wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS}.zip
  - unzip -d android-sdk-linux android-sdk.zip
  - echo y | android-sdk-linux/tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}" >/dev/null
  - echo y | android-sdk-linux/tools/bin/sdkmanager "platform-tools" >/dev/null
  - echo y | android-sdk-linux/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS}" >/dev/null
  - export ANDROID_HOME=$PWD/android-sdk-linux
  - export PATH=$PATH:$PWD/android-sdk-linux/platform-tools/
  - chmod +x ./gradlew
  # temporarily disable checking for EPIPE error and use yes to accept all licenses
  - set +o pipefail
  - yes | android-sdk-linux/tools/bin/sdkmanager --licenses
  - set -o pipefail

stages:
  - build
  - test

lintDebug:
  stage: build
  script:
    - ./gradlew -Pci --console=plain :app:lintDebug -PbuildDir=lint

assembleDebug:
  stage: build
  script:
    - ./gradlew assembleDebug
  artifacts:
    paths:
    - app/build/outputs/

debugTests:
  stage: test
  script:
    - ./gradlew -Pci --console=plain :app:testDebug
```

This CI define 2 main stages, build and test, in the first one it will perform some lint task and then build for debug purposes the application, the test stage instead is used to run tests. The before script session will be performed before every job in order to prepare the environment. The entire build/test process will be performed in docker containers.  

## Combine fastlane and Gitlab: use case with Ionic

Although, as discussed previously, Fastlane is mainly designed for natvie mobile app development it supports also third part frameworks like [Ionic](https://ionicframework.com/) through its plugin mechanism; combined with Gitlab CI pipelines, the automation process will be very straightforward.  
First of all the developer have to do the Fastlane setup process for all the platform that he wants to support (Android and/or iOS) producing the ``Fastfile`` and the ``Appfile``, personally I prefer to group all the Fastlane-relative files in a single folder on the root of the application project; another step that has to be done before proceed, or at least before the first release in production/beta/alpha round, is the merge of the AppFile for the credentials of Android and iOS. 



```ruby
platform :android do
  desc "Build the Android stuff in order to check if everything is correct"
  lane :build do
    ionic(platform: 'android', release: false, device: false)
  end

  desc "Upload to alpha channel"
  lane :alpha do
    current_dir=Dir.pwd
    ionic(platform: 'android', device: false, keystore_path: current_dir+'/my-release-key.keystore', keystore_password: ENV['STORE_PASS'], keystore_alias: '<your-key-alias>')
    upload_to_play_store(track: 'alpha', json_key:current_dir+'/api.json', apk: 'platforms/android/app/build/outputs/apk/release/app-release.apk')
  end

  desc "Upload to beta channel"
  lane :beta do
    current_dir=Dir.pwd
    ionic(platform: 'android', device: false, keystore_path: current_dir+'/my-release-key.keystore', keystore_password: ENV['STORE_PASS'], keystore_alias: '<your-key-alias>')
    upload_to_play_store(track: 'beta', json_key:current_dir+'/api.json', apk: 'platforms/android/app/build/outputs/apk/release/app-release.apk')
  end

  desc "Deploy a new version to the Google Play"
  lane :deploy do
    current_dir=Dir.pwd
    ionic(platform: 'android', device: false, keystore_path: current_dir+'/my-release-key.keystore', keystore_password: ENV['STORE_PASS'], keystore_alias: '<your-key-alias>')
    upload_to_play_store(json_key:current_dir+'/api.json', apk: 'platforms/android/app/build/outputs/apk/release/app-release.apk')
  end
end

platform :ios do

  desc "Build iOS in order to check if everthing is fine"
  lane :build do
    ionic(platform: 'ios', type: 'development', device: false, release: false)
  end

  desc "Upload to testflight"
  lane :beta do
    cert
    sigh
    ionic(platform: 'ios', device: false)
    ipa_path=gym(project:'./platforms/ios/<your-app-name>.xcodeproj',codesigning_identity:'<Code-signin-identity>')
    testflight(skip_waiting_for_build_processing: true, ipa: ipa_path)
  end

  desc "Upload to production"
  lane :deploy do
    cert
    sigh
    ionic(platform: 'ios', device: false)
    ipa_path=gym(project:'./platforms/ios/<your-app-name>.xcodeproj',codesigning_identity:'<Code-signin-identity>')
    deliver(ipa: ipa_path)
  end
end

```

```yaml
image: cmaiorano/ionic-builder

stages:
  - build
  - publish

cache:
  untracked: true
  key: "$CI_PROJECT_ID"
  paths:
    - node_modules/

build_android:
  stage: build
  before_script:
    - npm i
  script:
    - fastlane android build

release_ios:
  stage: publish
  only:
    - master
  before_script:
    - npm i
    - fastlane install_plugins
  script:
    - fastlane ios beta  
  tags:
    - macosx

release_android:
  stage: publish
  only:
    - master
  before_script:
  - npm i
  script:
    - fastlane android alpha

```