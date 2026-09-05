package com.vsm.ide

import android.os.Bundle
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import java.io.File

class EditorActivity : AppCompatActivity() {

    private lateinit var edtCode: EditText
    private lateinit var txtFilePath: TextView
    private var currentFile: File? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.getInsetsController(window, window.decorView)?.isAppearanceLightStatusBars = false
        setContentView(R.layout.activity_editor)

        edtCode = findViewById(R.id.edtCode)
        txtFilePath = findViewById(R.id.txtFilePath)

        val path = intent.getStringExtra("file_path")
        if (path != null) {
            currentFile = File(path)
            txtFilePath.text = path
            loadFile(currentFile!!)
        } else {
            txtFilePath.text = "(no file selected)"
        }

        findViewById<android.view.View>(R.id.btnSave).setOnClickListener { saveFile() }
    }

    private fun loadFile(file: File) {
        try {
            if (file.exists()) {
                edtCode.setText(file.readText())
            }
        } catch (e: Exception) {
            Toast.makeText(this, "Failed to read file: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun saveFile() {
        val file = currentFile
        if (file == null) {
            Toast.makeText(this, "No file to save", Toast.LENGTH_SHORT).show()
            return
        }
        try {
            file.parentFile?.mkdirs()
            file.writeText(edtCode.text.toString())
            Toast.makeText(this, "Saved: ${file.name}", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Toast.makeText(this, "Save failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
}
