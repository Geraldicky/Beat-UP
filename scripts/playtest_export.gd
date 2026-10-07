extends RefCounted
static func export_zip() -> Dictionary:
 var root: String = "user://playtest_exports"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
 var path: String = root + "/Beat_UP_playtest_%d.zip" % int(Time.get_unix_time_from_system())
 var pack := ZIPPacker.new()
 if pack.open(path) != OK: return {"ok": false, "message": "Could not create export."}
 var paths: Array[String] = []
 _collect("user://playtest_data", paths)
 _collect("user://performance", paths)
 _collect("user://replays", paths)
 for extra: String in ["user://best_level_stats.json", "user://user_settings.json"]:
  if FileAccess.file_exists(extra): paths.append(extra)
 var count: int = 0
 for source: String in paths:
  var file := FileAccess.open(source, FileAccess.READ)
  if file == null:
   pack.close()
   DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
   return {"ok": false, "message": "Could not read " + source}
  var bytes: PackedByteArray = file.get_buffer(file.get_length())
  if pack.start_file(source.trim_prefix("user://")) != OK or pack.write_file(bytes) != OK or pack.close_file() != OK:
   pack.close()
   DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
   return {"ok": false, "message": "Could not write export."}
  count += 1
 var status: Error = pack.close()
 return {"ok": status == OK, "message": "%d files exported" % count, "path": ProjectSettings.globalize_path(path), "folder": ProjectSettings.globalize_path(root)}
static func _collect(root: String, paths: Array[String]) -> void:
 var dir := DirAccess.open(root)
 if dir == null: return
 for filename: String in dir.get_files():
  if filename.ends_with(".json"): paths.append(root.path_join(filename))
 for folder: String in dir.get_directories():
  _collect(root.path_join(folder), paths)
