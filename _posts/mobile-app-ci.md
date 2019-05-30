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

So far everthing seems a standard procedure, but among the jungle of mobile development frameworks (ionic, flutter, native development) is not! If the test part could be easily made using one of the test frameworks for the selected platform (in combination with the development framework)