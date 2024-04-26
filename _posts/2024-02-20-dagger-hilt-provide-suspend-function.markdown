---
layout: post
title: "Dagger Hilt: @Provides a suspend function"
date: 2024-02-20 09:00
image: /assets/images/screenshot_dagger_hilt.png
headerImage: true
tag:
- android
- dagger hilt
- coroutine
- kotlin
category: blog
author: ugo
description: Resolving compile-time issues with Injecting suspending functions directly with Dagger Hilt
hidden: false
---

## Introduction

I was working on an Android application where I need to save an image (a user's photo) asynchronously as part of the sign up process. To achieve this I defined a suspending function to handle the image saving operation asynchronously in the background without blocking the main thread. I then wanted to make this suspending function injectable into a ViewModel by defining a [Dagger Hilt](TODO!)'s @Provides annotated function in a Hilt module. Well, the compiler threw a hissy fit and refused to build the code. 

This blog post explores this issue and demonstrates how your asynchronous functions can be integrated into your dependency injection setup.

## The Challenge

Here's how I initially attempted to set up the Hilt module:

```
// Typealias for a suspending function
typealias LogoImageSaver = suspend (Uri) -> Result<String>

@Qualifier
annotation class LogoSaverLambda

@Module
@InstallIn(SingletonComponent::class)
object EstablishmentSetUpLogicModule {

    @LogoSaverLambda
    @Provides
    fun provideLogoSaverModule(
        @ApplicationContext context: Context,
        @IoDispatcher coroutineDispatcher: CoroutineDispatcher,
    ): LogoImageSaver = { imageUri ->
        coroutineScope {
            val fileName = imageUri.lastPathSegment ?: "logo_image.jpg"
            withContext(coroutineDispatcher) {
                try {
                    val inputStream = context.contentResolver.openInputStream(imageUri)
                    val outputStream = context.openFileOutput(fileName, Context.MODE_PRIVATE)
                    inputStream?.use { input ->
                        outputStream.use { output ->
                            input.copyTo(output)
                        }
                    }
                    Result.success(fileName)
                } catch (e: Exception) {
                    Result.failure(e)
                }
            }
        }
    }
}

```
Attempting to compile this code results in a Dagger/Hilt error:
```
error: [Dagger/MissingBinding] kotlin.jvm.functions.Function2<? super android.net.Uri,? super kotlin.coroutines.Continuation<?>,?> cannot be provided without an @Provides-annotated method.
```

### Understanding the Issue

The root of the problem lies in how Dagger (and by extension, Hilt) processes suspending functions. Since suspending functions are transformed by the Kotlin compiler to include an additional `Continuation` parameter, Dagger fails to understand this transformation, leading to the aforementioned compile-time error.

## The Solution

The key to resolving this issue is to encapsulate the suspending function within a class or interface, thereby hiding the coroutine-specific details from Dagger/Hilt and making the dependency injection straightforward.

### Wrapping the Suspending Function in an Interface
```
interface LogoImageSaver {
    suspend fun saveImage(imageUri: Uri): Result<String>
}

@Module
@InstallIn(SingletonComponent::class)
object EstablishmentSetUpLogicModule {

    @Provides
    fun provideLogoSaver(
        @ApplicationContext context: Context,
        @IoDispatcher coroutineDispatcher: CoroutineDispatcher
    ): LogoImageSaver = object : LogoImageSaver {
        override suspend fun saveImage(imageUri: Uri): Result<String> = withContext(coroutineDispatcher) {
            try {
                val fileName = imageUri.lastPathSegment ?: "logo_image.jpg"
                val inputStream = context.contentResolver.openInputStream(imageUri)
                val outputStream = context.openFileOutput(fileName, Context.MODE_PRIVATE)
                inputStream?.use { input ->
                    outputStream.use { output ->
                        input.copyTo(output)
                    }
                }
                Result.Success(fileName)
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }
}
```

## Injecting the Interface

Finally, we inject the LogoImageSaver interface wherever needed, rather than the suspending function directly. This approach allows Dagger to manage the dependency injection smoothly, as it now deals with a concrete implementation of an interface, a pattern it understands well.

```
class SomeViewModel @Inject constructor(private val logoImageSaver: LogoImageSaver) : ViewModel() {
    fun saveLogo(imageUri: Uri) {
        viewModelScope.launch {
            val result = logoImageSaver.saveImage(imageUri)
            // Handle the result
        }
    }
}
```

## Conclusion

Injecting suspending functions directly with Hilt can lead to compile-time errors due to the way Dagger processes function types. Encapsulating suspending functions within interfaces or classes not only resolves these issues but also enhances the modularity and testability of your code. This pattern allows you to still use Kotlin Coroutines and Hilt in your Android applications, ensuring clean, maintainable, and efficient asynchronous operations with robust dependency injection.