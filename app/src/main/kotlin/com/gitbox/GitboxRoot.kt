package com.gitbox

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.gitbox.ui.theme.GitboxTheme

/**
 * Composition root. The terminal shell, file explorer, and code editor
 * screens are added here behind a NavHost once the domain/UI layers are approved.
 */
@Composable
fun GitboxRoot() {
    GitboxTheme {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "gitbox@shell:~$ awaiting architecture approval_",
                color = Color(0xFF00FF66),
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}
