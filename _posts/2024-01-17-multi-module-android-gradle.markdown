---
title: "Multi-Module Android Apps: Lessons learnt trying to Isolate a Firestore-based Data Source Module."
layout: post
date: 2024-01-17 14:48
image: /assets/images/markdown.jpg
headerImage: false
tag:
- android
- gradle
- multimodule
category: blog
author: ugo
description: Learning gotchas from building multi-module android apps
hidden: false
---

When developing multi-module Android apps, I tend to prefer creating non-Android Java/Kotlin Gradle modules, i.e. modules without the `com.android.library` plugins added to the `build.gradle` file. It keeps things simpler by eliminating the complexity of Android-specific dependencies; just plain-old Kotlin/Java classes that are easier to unit test and swap around.

However, I learnt the hard way that some libraries don’t play nice with such thinking. It took me a day and some more to finally learn that you can’t use Firebase Firestore (and some other similar Firebase libraries) in non-Android Java/Kotlin Gradle modules. The idea is to create a separate Gradle module to encapsulate a `datasource` layer in an MVVM architecture. Specifically, this was meant to be a `:datasource:firestore` Gradle module, which implements the interfaces defined in a separate `datasource:api` module regarding interactions with data persistence and retrieval, following the official Android guide [here](...).



[Here’s](https://stackoverflow.com/a/75434948/2077405) where I got this revelation after trying loads of trickery to get the add Firestore dependency to be loaded into the classpath as suggested by Android Studio intellisense as a solution to not being able to compile my code.

Specifically, the answer came from Stackoverflow Android guru, CommonsWare:
> `com.google.firebase:firebase-crashlytics-ktx` depends on `com.google.firebase:firebase-crashlytics`, which depends on `com.google.android.gms:play-services-tasks`, which is part of Play Services and only exists on Android.

There’s also this [Stackoverflow post](https://stackoverflow.com/a/59514533/2077405) too, which ultimately guided me to the solution I went with to get this airey:

> The problem was that I tried to use firestore inside a pure kotlin library, to solve the problem I had to add: `apply plugin: 'com.android.library'`, and `apply plugin: 'kotlin-android'`, and an `android` block to the gradle file of the module. (Basically I had to convert my kotlin library to an android library)

Hope this helps anyone out there struggling with this.