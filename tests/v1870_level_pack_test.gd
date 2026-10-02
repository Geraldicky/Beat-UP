extends SceneTree

const LevelPackScript = preload("res://scripts/level_pack.gd")
const ReliableJsonStoreScript = preload("res://scripts/reliable_json_store.gd")
const ROOT := "user://songs/v1870_pack_test"
const PACK := "user://level_packs/v1870_pack_test.beatup-pack"

var failed := false

func _init() -> void:
	_cleanup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var audio := FileAccess.open(ROOT.path_join("audio.ogg"), FileAccess.WRITE)
	_check(audio != null, "Could not create test audio")
	if audio != null:
		audio.store_buffer(PackedByteArray([79, 103, 103, 83, 0, 2, 3, 4]))
		audio.close()
	var chart := {
		"id": "v1870_pack_test_normal",
		"song_id": "v1870_pack_test",
		"title": "Creator Pack Test",
		"artist": "Beat UP! QA",
		"difficulty": "NORMAL",
		"chart_difficulty": "normal",
		"star_rating": 1,
		"audio": ROOT.path_join("audio.ogg"),
		"bpm": 120.0,
		"duration": 4.0,
		"events": [{"time": 1.0, "type": "normal", "direction": 8}],
		"space_events": [2.0],
	}
	_check(ReliableJsonStoreScript.save_dictionary_atomic(ROOT.path_join("normal.json"), chart), "Could not create source chart")
	var exported: Dictionary = LevelPackScript.export_song("v1870_pack_test", PACK, true)
	_check(bool(exported.get("ok", false)), "Level-pack export failed: %s" % str(exported.get("error", "")))
	_remove_tree(ROOT)
	var imported: Dictionary = LevelPackScript.import_pack(PACK)
	_check(bool(imported.get("ok", false)), "Level-pack import failed: %s" % str(imported.get("error", "")))
	_check(FileAccess.file_exists(ROOT.path_join("normal.json")), "Imported chart is missing")
	_check(FileAccess.file_exists(ROOT.path_join("audio.ogg")), "Imported audio is missing")

	var unsafe_pack := "user://level_packs/v1870_unsafe.beatup-pack"
	var packer := ZIPPacker.new()
	_check(packer.open(ProjectSettings.globalize_path(unsafe_pack)) == OK, "Could not create unsafe fixture")
	if packer.start_file("../escape.txt") == OK:
		packer.write_file("unsafe".to_utf8_buffer())
		packer.close_file()
	packer.close()
	var unsafe_result: Dictionary = LevelPackScript.import_pack(unsafe_pack)
	_check(not bool(unsafe_result.get("ok", false)), "Path traversal pack was accepted")

	_cleanup()
	if not failed:
		print("Beat UP! v18.7.0 level-pack runtime QA: PASS")
	quit(1 if failed else 0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)

func _cleanup() -> void:
	_remove_tree(ROOT)
	for path: String in [PACK, "user://level_packs/v1870_unsafe.beatup-pack"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var child: String = path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
