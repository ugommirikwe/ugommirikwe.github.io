---
layout: post
title: "Riverpod 2.0: Quick Notes on Read/Write StateProviders"
date: 2024-08-13 09:00
image: /assets/images/riverpod-generator-syntax-migration/screenshot-riverpod-generator-syntax-migration_2.png
headerImage: true
tag:
- riverpod
- flutter
- state management
category: blog
author: ugo
description: A brief note on not making mistakes when implementing read-only vs read/write Riverpod StateProviders.
hidden: false
---

# Overview

The release of Riverpod 2.0 provided a shift towards a more modern syntax for defining [providers](https://riverpod.dev/docs/concepts/providers) by using the `@riverpod` annotation. However, this new syntax can lead to some confusion when migrating from the older `StateProvider` approach. You'll see how to avoid the embarrasingly simple mistake I made while migrating an existing state provider to using Riverpod 2.0.

# The Basics: @riverpod Annotation

In Riverpod 2.0, using the `@riverpod` annotation on a function creates a read-only provider. This is useful when you want to expose immutable data. Here’s an example:

```dart
@riverpod
String searchField(SearchFieldRef ref) {
  return '';
}
```

This replaces the older syntax:

```dart
final searchFieldProvider = StateProvider<String>((ref) => '');
```

But there’s an important difference: the `@riverpod` annotation creates a [Provider](https://riverpod.dev/docs/concepts/providers#creating-a-provider) which is read-only unlike the older syntax. This means that attempting to modify this state using:

```dart
TextField(
  controller: _searchTextFieldController,
  onChanged: (value) {
    ref.read(searchFieldProvider.notifier).state = value; // <=
  },
)
``` 
will work if you use the older syntax to define your `StateProvider`, but will result in an error quite similar to the below:

```bash
The getter 'notifier' isn't defined for the type 'AutoDisposeProvider<String>'
```
This is because the provider auto-generated with the `@riverpod` annotation doesn’t have a notifier. In Riverpod 2.0, the notifier property has been removed from `Provider` and `StateProvider`.

# Implementing a Read/Write Provider

In Riverpod 2.0, the StateProvider has been deprecated in favor of the new StateNotifierProvider. The StateNotifierProvider is more powerful and flexible, allowing you to encapsulate the state management logic within a separate class (StateNotifier).

By using the `@riverpod` syntax with the `extends _$SearchField` approach, we're creating a `StateNotifierProvider` under the hood, which is why it is required to implement a state mutation method to modify the state.

To implement a read/write provider in Riverpod 2.0, you can use one of the following approaches:

## Using a Custom Class

You can manage the state by defining a custom class with the @riverpod annotation. Here’s how:

```dart
@riverpod
class SearchField extends _$SearchField {
  @override
  String build() {
    return '';
  }

  void update(String value) { // <== this custom function enables mutation of state
    state = value;
  }
}
```

Now, in your Flutter widget, you can update the state like this:

```dart
TextField(
  controller: _searchTextFieldController,
  onChanged: (value) {
    ref.read(searchFieldProvider.notifier).update(value); // <== see how it's used
  },
)
```

## Using the Legacy `StateProvider` Alternative

If you prefer a more straightforward approach without defining a custom class, you can still use the legacy `StateProvider` syntax like so:

```dart
final searchFieldProvider = StateProvider<String>((ref) => '');
```

This keeps things simple and gives you the notifier to update the state directly:

```dart
TextField(
  controller: _searchTextFieldController,
  onChanged: (value) {
    ref.read(searchFieldProvider.notifier).state = value;
  },
)
```

# Conclusion

So, there ya go! Don't be like me: read the darn documentation very well 😏
