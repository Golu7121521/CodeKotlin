package com.vsm.ide

import android.content.Context
import java.io.File

/**
 * Workspace now lives under the app's own external-files directory
 * (/storage/emulated/0/Android/data/<package>/files/Vscode). This needs
 * NO runtime permission on any Android version -- it's always writable
 * by the app -- unlike arbitrary shared-storage paths, which require
 * MANAGE_EXTERNAL_STORAGE on Android 11+ and are easy to get wrong.
 */
object StorageUtil {

    /** Human-readable label only; actual path is resolved per-Context below. */
    const val WORKSPACE_LABEL = "Android/data/<package>/files/Vscode"

    fun workspaceDir(context: Context): File {
        val base = context.getExternalFilesDir(null)
            ?: context.filesDir // fallback if external storage is ever unavailable
        val dir = File(base, "Vscode")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    /** Always true now -- no special permission needed for app-scoped storage. */
    fun hasStoragePermission(): Boolean = true
}
