package com.vsm.ide

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import java.io.File

class ExplorerActivity : AppCompatActivity() {

    private lateinit var recycler: RecyclerView
    private lateinit var txtPath: TextView
    private lateinit var adapter: FileListAdapter
    private lateinit var currentDir: File
    private val rootDir = File(StorageUtil.WORKSPACE_PATH)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.getInsetsController(window, window.decorView)?.isAppearanceLightStatusBars = false
        setContentView(R.layout.activity_explorer)

        recycler = findViewById(R.id.recyclerFiles)
        txtPath = findViewById(R.id.txtPath)
        recycler.layoutManager = LinearLayoutManager(this)

        currentDir = if (rootDir.exists()) rootDir else StorageUtil.workspaceDir()

        adapter = FileListAdapter(emptyList()) { file -> onFileClicked(file) }
        recycler.adapter = adapter

        loadDir(currentDir)
    }

    private fun loadDir(dir: File) {
        currentDir = dir
        txtPath.text = dir.absolutePath
        val children = (dir.listFiles()?.toList() ?: emptyList())
            .sortedWith(compareBy({ !it.isDirectory }, { it.name.lowercase() }))
        adapter.update(children)
    }

    private fun onFileClicked(file: File) {
        if (file.isDirectory) {
            loadDir(file)
        } else {
            val intent = Intent(this, EditorActivity::class.java)
            intent.putExtra("file_path", file.absolutePath)
            startActivity(intent)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val parent = currentDir.parentFile
        val rootPath = File(StorageUtil.WORKSPACE_PATH).absolutePath
        if (parent != null && currentDir.absolutePath != rootPath) {
            loadDir(parent)
        } else {
            super.onBackPressed()
        }
    }
}
