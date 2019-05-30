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

[Fastlane](https://fastlane.tools/) is a build tools for fast release of the application, which supports also