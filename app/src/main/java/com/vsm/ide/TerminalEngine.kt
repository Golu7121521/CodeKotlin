package com.vsm.ide

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import java.io.File
import java.util.zip.ZipInputStream

/**
 * Executes terminal command strings. Every function here is expected to run
 * on a background thread (Dispatchers.IO) -- the caller (MainActivity) is
 * responsible for hopping back to the main thread to update the UI.
 */
class TerminalEngine(private val appContext: Context) {

    private val prefs: SharedPreferences =
        appContext.getSharedPreferences("vsc_prefs", Context.MODE_PRIVATE)

    private fun token(): String = prefs.getString("gh_token", "") ?: ""

    private fun workspace(): File = StorageUtil.workspaceDir(appContext)

    fun helpText(): String = """
        Available commands:
          help                                  Show this help
          clear                                 Clear the terminal
          token <pat>                            Save your GitHub Personal Access Token
          clone <owner/repo>                     Clone a repo into $WORKSPACE_LABEL
          files                                  Open the file explorer
          edit                                   Open the code editor
          push <owner/repo> <path> <msg>          Push a single file
          pushall <owner/repo> <msg>              Push the whole project (git tree flow)
          build <owner/repo> <workflow.yml>       Trigger a GitHub Actions workflow
          status <owner/repo>                    Check latest workflow run status
          download <owner/repo>                  Open Actions page to grab build artifacts
    """.trimIndent()

    fun saveToken(pat: String): String {
        prefs.edit().putString("gh_token", pat).apply()
        return "Token saved (${pat.length} chars)."
    }

    fun clone(ownerRepo: String): String {
        requireToken()
        val api = GitHubApi(token())
        val zipBytes = api.downloadRepoZip(ownerRepo)
        val destName = ownerRepo.replace("/", "_")
        val destDir = File(workspace(), destName)
        if (destDir.exists()) destDir.deleteRecursively()
        destDir.mkdirs()

        ZipInputStream(zipBytes.inputStream()).use { zis ->
            var entry = zis.nextEntry
            var rootFolderName: String? = null
            while (entry != null) {
                val parts = entry.name.split("/", limit = 2)
                if (rootFolderName == null) rootFolderName = parts[0]
                val relative = if (parts.size > 1) parts[1] else ""
                if (relative.isNotEmpty()) {
                    val outFile = File(destDir, relative)
                    if (entry.isDirectory) {
                        if (!outFile.exists() && !outFile.mkdirs()) {
                            throw IllegalStateException(
                                "Failed to create directory: ${outFile.absolutePath}"
                            )
                        }
                    } else {
                        val parent = outFile.parentFile
                        if (parent != null && !parent.exists() && !parent.mkdirs()) {
                            throw IllegalStateException(
                                "Failed to create directory: ${parent.absolutePath}"
                            )
                        }
                        outFile.outputStream().use { fos ->
                            zis.copyTo(fos)
                        }
                    }
                }
                zis.closeEntry()
                entry = zis.nextEntry
            }
        }
        return "Cloned into: ${destDir.absolutePath}"
    }

    fun pushFile(ownerRepo: String, relativePath: String, message: String): String {
        requireToken()
        val destName = ownerRepo.replace("/", "_")
        val projectDir = File(workspace(), destName)
        val file = File(projectDir, relativePath)
        if (!file.exists()) return "File not found: ${file.absolutePath}"

        val content = file.readBytes()
        val base64 = Base64.encodeToString(content, Base64.NO_WRAP)
        val api = GitHubApi(token())
        api.putFileContent(ownerRepo, relativePath, base64, message)
        return "Pushed $relativePath -> $ownerRepo"
    }

    fun pushAll(ownerRepo: String, message: String): String {
        requireToken()
        val destName = ownerRepo.replace("/", "_")
        val projectDir = File(workspace(), destName)
        if (!projectDir.exists()) return "Project not found locally: ${projectDir.absolutePath}"

        val api = GitHubApi(token())
        val files = api.collectProjectFiles(projectDir)
        if (files.isEmpty()) return "No files found to push."

        val blobEntries = mutableListOf<Pair<String, String>>()
        for ((relPath, file) in files) {
            val base64 = Base64.encodeToString(file.readBytes(), Base64.NO_WRAP)
            val blobSha = api.createBlob(ownerRepo, base64)
            blobEntries.add(relPath to blobSha)
        }

        val latestCommitSha = api.getLatestCommitSha(ownerRepo)
        val baseTreeSha = api.getCommitTreeSha(ownerRepo, latestCommitSha)
        val newTreeSha = api.createTree(ownerRepo, baseTreeSha, blobEntries)
        val newCommitSha = api.createCommit(ownerRepo, message, newTreeSha, latestCommitSha)
        api.updateRef(ownerRepo, newCommitSha)

        return "Pushed ${files.size} file(s) to $ownerRepo (commit $newCommitSha)."
    }

    fun triggerBuild(ownerRepo: String, workflowFile: String): String {
        requireToken()
        val api = GitHubApi(token())
        api.triggerWorkflow(ownerRepo, workflowFile)
        return "Workflow '$workflowFile' dispatched for $ownerRepo."
    }

    fun checkStatus(ownerRepo: String): String {
        requireToken()
        val api = GitHubApi(token())
        return api.getLatestRunStatus(ownerRepo)
    }

    fun downloadUrl(ownerRepo: String): String {
        val api = GitHubApi(token())
        return api.getActionsPageUrl(ownerRepo)
    }

    private fun requireToken() {
        if (token().isBlank()) {
            throw IllegalStateException("No GitHub token set. Use: token <your_pat>")
        }
    }

    companion object {
        const val WORKSPACE_LABEL = StorageUtil.WORKSPACE_LABEL
    }
}
