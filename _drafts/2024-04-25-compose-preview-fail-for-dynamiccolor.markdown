---
layout: post
title: "Jetpack Compose Preview Failure for dynamicColor Defaults"
date: 2024-02-17 21:00
image: /assets/images/post-images-compose-preview/screenshot-compose-theme-function.png
headerImage: true
tag:
- android
- jetpack compose
- theme
category: blog
author: ugo
description: Jetpack Compose Preview fails when using the dynamicColor API.
hidden: true
---

I made a couple of updates to the dependencies in an Android app I was working on and suddenly the Jetpack Compose preview stopped rendering, while Android Studio spews out a stack trace:
```
...
android.content.res.Resources$NotFoundException: Could not resolve resource value: 0x1060060.   at android.content.res.Resources_Delegate.throwException(Resources_Delegate.java:1159)   at android.content.res.Resources_Delegate.throwException(Resources_Delegate.java:1135)   at android.content.res.Resources_Delegate.throwException(Resources_Delegate.java:1139)   at android.content.res.Resources_Delegate.getColorStateList(Resources_Delegate.java:268)   at android.content.res.Resources_Delegate.getColor(Resources_Delegate.java:246)   at android.content.res.Resources.getColor(Resources.java:1065)   at androidx.compose.material3.ColorResourceHelper.getColor-WaAFU9c(DynamicTonalPalette.android.kt:205)   at androidx.compose.material3.DynamicTonalPaletteKt.dynamicLightColorScheme34(DynamicTonalPalette.android.kt:307)   at androidx.compose.material3.DynamicTonalPaletteKt.dynamicLightColorScheme(DynamicTonalPalette.android.kt:170)   at com.myapp.theme.ThemeKt.MyAppTheme(Theme.kt:51)
...
```

![Jetpack Compose Preview error screenshot](/assets/images/post-images-compose-preview/screenshot-compose-theme-error.png)

Following this stack trace points me to my app's Jetpack Compose Theme function:

```
@Composable
fun MyAppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }

        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
```

Specifically, the error points to the line:
```
...
else dynamicLightColorScheme(context)
...
```

as being the source of the issue.

Well, that didn't make sense to me as it was working a few days before I took a break from the project. 

## My Stack Certainly Overflowed

So, I proceeded down several Google rabbit holes until I stumbled upon [this Stackoverflow post](https://stackoverflow.com/a/75952884/2077405):

> <p>Whenever you will use device below android level 12 it will run as a preview but If you are trying to use device Above android 12+ you have change one in 'Theme.kt' file.</p>
> <p>Change dynamicColor: Boolean = true to dynamicColor: Boolean = false</p>
> <p>Now you will get output same as compose preview.</p>

What I understand from their explanation is that when your currently selected emulator or device in Android Studio runs on an Android OS version 12 or later then you have to change the `MyAppTheme(...)` function's `dynamicColor` parameter default value to `false` rather than `true` (see above code snippet where it's set to `true` by default).

```
@Composable
fun MyAppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = false, // <= set to false instead of true
    content: @Composable () -> Unit
) {
    ...
}
```

And it so happens that I had deleted my previous emulators and created a new one running on Android OS 13 (API 33) 