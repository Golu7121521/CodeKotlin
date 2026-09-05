package com.vsm.ide

import okhttp3.Credentials
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Thin wrapper around the GitHub REST API used by the terminal commands.
 * All methods are synchronous/blocking and are expected to be called
 * from a background coroutine (Dispatchers.IO).
 */
class GitHubApi(private val token: String) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()

    private val jsonMedia = "application/json".toMediaType()
    private val base = "https://api.github.com"

    private fun authHeader(): String = "Bearer $token"

    private fun get(url: String): String {
        val req = Request.Builder()
            .url(url)
            .header("Authorization", authHeader())
            .header("Accept", "application/vnd.github+json")
            .get()
            .build()
        client.newCall(req).execute().use { resp ->
            val body = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw RuntimeException("GET $url failed [${resp.code}]: $body")
            return body
        }
    }

    private fun getRaw(url: String): ByteArray {
        val req = Request.Builder()
            .url(url)
            .header("Authorization", authHeader())
            .get()
            .build()
        client.newCall(req).execute().use { resp ->
            if (!resp.isSuccessful) throw RuntimeException("GET(raw) $url failed [${resp.code}]")
            return resp.body?.bytes() ?: ByteArray(0)
        }
    }

    private fun post(url: String, jsonBody: String): String {
        val body = jsonBody.toRequestBody(jsonMedia)
        val req = Request.Builder()
            .url(url)
            .header("Authorization", authHeader())
            .header("Accept", "application/vnd.github+json")
            .post(body)
            .build()
        client.newCall(req).execute().use { resp ->
            val respBody = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw RuntimeException("POST $url failed [${resp.code}]: $respBody")
            return respBody
        }
    }

    private fun put(url: String, jsonBody: String): String {
        val body = jsonBody.toRequestBody(jsonMedia)
        val req = Request.Builder()
            .url(url)
            .header("Authorization", authHeader())
            .header("Accept", "application/vnd.github+json")
            .put(body)
            .build()
        client.newCall(req).execute().use { resp ->
            val respBody = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw RuntimeException("PUT $url failed [${resp.code}]: $respBody")
            return respBody
        }
    }

    private fun patch(url: String, jsonBody: String): String {
        val body = jsonBody.toRequestBody(jsonMedia)
        val req = Request.Builder()
            .url(url)
            .header("Authorization", authHeader())
            .header("Accept", "application/vnd.github+json")
            .patch(body)
            .build()
        client.newCall(req).execute().use { resp ->
            val respBody = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw RuntimeException("PATCH $url failed [${resp.code}]: $respBody")
            return respBody
        }
    }

    /** Downloads the repo's default-branch zipball. */
    fun downloadRepoZip(ownerRepo: String): ByteArray {
        val url = "$base/repos/$ownerRepo/zipball"
        return getRaw(url)
    }

    /** GET the latest SHA of a file, or null if it does not yet exist. */
    fun getFileSha(ownerRepo: String, path: String, branch: String = "main"): String? {
        return try {
            val url = "$base/repos/$ownerRepo/contents/$path?ref=$branch"
            val json = JSONObject(get(url))
            json.optString("sha", null)
        } catch (e: Exception) {
            null
        }
    }

    /** Create or update a single file via the Contents API. */
    fun putFileContent(
        ownerRepo: String,
        path: String,
        base64Content: String,
        message: String,
        branch: String = "main"
    ): String {
        val sha = getFileSha(ownerRepo, path, branch)
        val url = "$base/repos/$ownerRepo/contents/$path"
        val body = JSONObject().apply {
            put("message", message)
            put("content", base64Content)
            put("branch", branch)
            if (sha != null) put("sha", sha)
        }
        return put(url, body.toString())
    }

    /** Gets the latest commit SHA on a branch. */
    fun getLatestCommitSha(ownerRepo: String, branch: String = "main"): String {
        val url = "$base/repos/$ownerRepo/git/ref/heads/$branch"
        val json = JSONObject(get(url))
        return json.getJSONObject("object").getString("sha")
    }

    /** Gets the tree SHA referenced by a commit. */
    fun getCommitTreeSha(ownerRepo: String, commitSha: String): String {
        val url = "$base/repos/$ownerRepo/git/commits/$commitSha"
        val json = JSONObject(get(url))
        return json.getJSONObject("tree").getString("sha")
    }

    /** Create a git blob, returns the blob SHA. */
    fun createBlob(ownerRepo: String, base64Content: String): String {
        val url = "$base/repos/$ownerRepo/git/blobs"
        val body = JSONObject().apply {
            put("content", base64Content)
            put("encoding", "base64")
        }
        val json = JSONObject(post(url, body.toString()))
        return json.getString("sha")
    }

    /** Create a new tree from a list of (path, blobSha) pairs, based on baseTreeSha. */
    fun createTree(ownerRepo: String, baseTreeSha: String, entries: List<Pair<String, String>>): String {
        val url = "$base/repos/$ownerRepo/git/trees"
        val treeArray = JSONArray()
        for ((path, sha) in entries) {
            treeArray.put(JSONObject().apply {
                put("path", path)
                put("mode", "100644")
                put("type", "blob")
                put("sha", sha)
            })
        }
        val body = JSONObject().apply {
            put("base_tree", baseTreeSha)
            put("tree", treeArray)
        }
        val json = JSONObject(post(url, body.toString()))
        return json.getString("sha")
    }

    /** Create a new commit pointing at newTreeSha, with parentSha as its parent. */
    fun createCommit(ownerRepo: String, message: String, newTreeSha: String, parentSha: String): String {
        val url = "$base/repos/$ownerRepo/git/commits"
        val body = JSONObject().apply {
            put("message", message)
            put("tree", newTreeSha)
            put("parents", JSONArray().put(parentSha))
        }
        val json = JSONObject(post(url, body.toString()))
        return json.getString("sha")
    }

    /** Force-update a branch ref to point at newCommitSha. */
    fun updateRef(ownerRepo: String, newCommitSha: String, branch: String = "main") {
        val url = "$base/repos/$ownerRepo/git/refs/heads/$branch"
        val body = JSONObject().apply {
            put("sha", newCommitSha)
            put("force", true)
        }
        patch(url, body.toString())
    }

    /** Trigger a workflow_dispatch event for the given workflow file. */
    fun triggerWorkflow(ownerRepo: String, workflowFile: String, ref: String = "main") {
        val url = "$base/repos/$ownerRepo/actions/workflows/$workflowFile/dispatches"
        val body = JSONObject().apply {
            put("ref", ref)
        }
        post(url, body.toString())
    }

    /** Returns a human readable status/conclusion string for the latest workflow run. */
    fun getLatestRunStatus(ownerRepo: String): String {
        val url = "$base/repos/$ownerRepo/actions/runs?per_page=1"
        val json = JSONObject(get(url))
        val runs = json.getJSONArray("workflow_runs")
        if (runs.length() == 0) return "No workflow runs found."
        val run = runs.getJSONObject(0)
        val status = run.getString("status")
        val conclusion = run.optString("conclusion", "pending")
        val name = run.optString("name", "workflow")
        val htmlUrl = run.optString("html_url", "")
        return "Run: $name\nStatus: $status\nConclusion: $conclusion\nURL: $htmlUrl"
    }

    /** Returns the Actions run list page URL for viewing/downloading artifacts in a browser. */
    fun getActionsPageUrl(ownerRepo: String): String {
        return "https://github.com/$ownerRepo/actions"
    }

    /** Recursively walk a directory and build (relativePath -> File) pairs, skipping hidden files. */
    fun collectProjectFiles(root: File): List<Pair<String, File>> {
        val results = mutableListOf<Pair<String, File>>()
        fun walk(dir: File, prefix: String) {
            val children = dir.listFiles() ?: return
            for (child in children) {
                if (child.name.startsWith(".")) continue
                val relPath = if (prefix.isEmpty()) child.name else "$prefix/${child.name}"
                if (child.isDirectory) {
                    walk(child, relPath)
                } else {
                    results.add(relPath to child)
                }
            }
        }
        walk(root, "")
        return results
    }
}
