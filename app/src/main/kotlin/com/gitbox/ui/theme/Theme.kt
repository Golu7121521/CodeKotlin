package com.gitbox.ui.theme

import android.os.Build
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

private val GitboxDarkColorScheme = darkColorScheme(
    primary = NeonGreen,
    onPrimary = TerminalBackground,
    secondary = NeonGreenDim,
    onSecondary = TerminalBackground,
    tertiary = AmberWarn,
    error = RedError,
    background = TerminalBackground,
    onBackground = TextPrimary,
    surface = TerminalSurface,
    onSurface = TextPrimary,
    surfaceVariant = TerminalSurfaceVariant,
    onSurfaceVariant = TextDim,
    outline = Outline,
)

/**
 * Gitbox always renders in the dark terminal aesthetic. Dynamic color (Android 12+)
 * is opt-in and only tints accents — background stays true terminal black.
 */
@Composable
fun GitboxTheme(
    useDynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    val colorScheme = when {
        useDynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            dynamicDarkColorScheme(context).copy(background = TerminalBackground, surface = TerminalSurface)
        else -> GitboxDarkColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = GitboxTypography,
        content = content
    )
}
