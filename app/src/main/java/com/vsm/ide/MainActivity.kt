package com.vsm.ide

import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.text.SpannableStringBuilder
import android.text.style.ForegroundColorSpan
import android.view.WindowManager
import android.widget.EditText
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AppCompatActivity() {

    private lateinit var txtOutput: TextView
    private lateinit var scrollOutput: ScrollView
    private lateinit var edtCommand: EditText
    private lateinit var engine: TerminalEngine

    private val scope = CoroutineScope(Dispatchers.Main)
    private val neonGreen = 0xFF00FF66.toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep the native status bar visible with dark background + white icons.
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        WindowCompat.getInsetsController(window, window.decorView)?.isAppearanceLightStatusBars = false

        setContentView(R.layout.activity_main)

        txtOutput = findViewById(R.id.txtOutput)
        scrollOutput = findViewById(R.id.scrollOutput)
        edtCommand = findViewById(R.id.edtCommand)
        engine = TerminalEngine(this)

        appendLine("VS Code Mobile IDE & CI/CD Terminal")
        appendLine("Workspace: ${StorageUtil.workspaceDir(this).absolutePath}")
        appendLine("Type 'help' to list commands.")
        appendLine("")

        findViewById<android.view.View>(R.id.btnExec).setOnClickListener { runCommandFromInput() }
        edtCommand.setOnEditorActionListener { _, _, _ ->
            runCommandFromInput()
            true
        }

        findViewById<android.view.View>(R.id.chipFiles).setOnClickListener {
            startActivity(Intent(this, ExplorerActivity::class.java))
        }
        findViewById<android.view.View>(R.id.chipStatus).setOnClickListener {
            edtCommand.setText("status ")
            edtCommand.setSelection(edtCommand.text.length)
        }
        findViewById<android.view.View>(R.id.chipClear).setOnClickListener {
            txtOutput.text = ""
        }
        findViewById<android.view.View>(R.id.chipHelp).setOnClickListener {
            appendLine(engine.helpText())
        }
    }

    private fun runCommandFromInput() {
        val cmd = edtCommand.text.toString().trim()
        if (cmd.isEmpty()) return
        edtCommand.setText("")
        appendPrompt(cmd)
        execute(cmd)
    }

    private fun appendPrompt(cmd: String) {
        appendLine("$ $cmd")
    }

    private fun appendLine(text: String) {
        val ssb = SpannableStringBuilder(txtOutput.text)
        if (ssb.isNotEmpty()) ssb.append("\n")
        val start = ssb.length
        ssb.append(text)
        ssb.setSpan(
            ForegroundColorSpan(neonGreen),
            start,
            ssb.length,
            SpannableStringBuilder.SPAN_EXCLUSIVE_EXCLUSIVE
        )
        txtOutput.text = ssb
        txtOutput.typeface = Typeface.MONOSPACE
        scrollOutput.post { scrollOutput.fullScroll(ScrollView.FOCUS_DOWN) }
    }

    private fun execute(cmdLine: String) {
        val tokens = tokenize(cmdLine)
        if (tokens.isEmpty()) return
        val cmd = tokens[0].lowercase()

        scope.launch {
            try {
                val result: String = withContext(Dispatchers.IO) {
                    when (cmd) {
                        "help" -> engine.helpText()
                        "clear" -> "__CLEAR__"
                        "token" -> {
                            if (tokens.size < 2) "Usage: token <pat>"
                            else engine.saveToken(tokens[1])
                        }
                        "clone" -> {
                            if (tokens.size < 2) "Usage: clone <owner/repo>"
                            else engine.clone(tokens[1])
                        }
                        "files" -> "__OPEN_FILES__"
                        "edit" -> "__OPEN_EDITOR__"
                        "push" -> {
                            if (tokens.size < 4) "Usage: push <owner/repo> <file_path> <commit_message>"
                            else engine.pushFile(tokens[1], tokens[2], tokens.drop(3).joinToString(" "))
                        }
                        "pushall" -> {
                            if (tokens.size < 3) "Usage: pushall <owner/repo> <commit_message>"
                            else engine.pushAll(tokens[1], tokens.drop(2).joinToString(" "))
                        }
                        "build" -> {
                            if (tokens.size < 3) "Usage: build <owner/repo> <workflow_file>"
                            else engine.triggerBuild(tokens[1], tokens[2])
                        }
                        "status" -> {
                            if (tokens.size < 2) "Usage: status <owner/repo>"
                            else engine.checkStatus(tokens[1])
                        }
                        "download" -> {
                            if (tokens.size < 2) "Usage: download <owner/repo>"
                            else "__DOWNLOAD__" + engine.downloadUrl(tokens[1])
                        }
                        else -> "Unknown command: $cmd (type 'help')"
                    }
                }
                handleResult(result)
            } catch (e: Exception) {
                appendLine("Error: ${e.message}")
            }
        }
    }

    private fun handleResult(result: String) {
        when {
            result == "__CLEAR__" -> txtOutput.text = ""
            result == "__OPEN_FILES__" -> startActivity(Intent(this, ExplorerActivity::class.java))
            result == "__OPEN_EDITOR__" -> startActivity(Intent(this, EditorActivity::class.java))
            result.startsWith("__DOWNLOAD__") -> {
                val url = result.removePrefix("__DOWNLOAD__")
                appendLine("Opening: $url")
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)))
                } catch (e: Exception) {
                    Toast.makeText(this, "Could not open browser", Toast.LENGTH_SHORT).show()
                }
            }
            else -> appendLine(result)
        }
    }

    private fun tokenize(line: String): List<String> {
        val result = mutableListOf<String>()
        val current = StringBuilder()
        var inQuotes = false
        for (c in line) {
            when {
                c == '"' -> inQuotes = !inQuotes
                c == ' ' && !inQuotes -> {
                    if (current.isNotEmpty()) {
                        result.add(current.toString())
                        current.clear()
                    }
                }
                else -> current.append(c)
            }
        }
        if (current.isNotEmpty()) result.add(current.toString())
        return result
    }
}
