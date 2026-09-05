package com.vsm.ide

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import java.io.File

class FileListAdapter(
    private var files: List<File>,
    private val onClick: (File) -> Unit
) : RecyclerView.Adapter<FileListAdapter.FileViewHolder>() {

    class FileViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val icon: ImageView = view.findViewById(R.id.imgIcon)
        val name: TextView = view.findViewById(R.id.txtName)
    }

    fun update(newFiles: List<File>) {
        files = newFiles
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FileViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_file, parent, false)
        return FileViewHolder(view)
    }

    override fun onBindViewHolder(holder: FileViewHolder, position: Int) {
        val file = files[position]
        holder.name.text = file.name
        holder.icon.setImageResource(iconFor(file))
        holder.itemView.setOnClickListener { onClick(file) }
    }

    override fun getItemCount(): Int = files.size

    private fun iconFor(file: File): Int {
        if (file.isDirectory) return R.drawable.ic_folder
        val codeExtensions = setOf("kt", "java", "dart", "gradle", "kts", "xml", "json", "py", "js", "ts")
        val ext = file.extension.lowercase()
        return if (ext in codeExtensions) R.drawable.ic_code else R.drawable.ic_file
    }
}
