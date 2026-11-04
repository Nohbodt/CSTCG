extends SceneTree

func _initialize() -> void:
	var output = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	if output.is_empty():
		printerr("Pass --output=/absolute/notices-directory")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(1)
		return
	var license_file = FileAccess.open(output.path_join("Godot-LICENSE.txt"), FileAccess.WRITE)
	if license_file == null:
		quit(1)
		return
	license_file.store_string(Engine.get_license_text())
	license_file.close()
	var notices = FileAccess.open(output.path_join("Godot-THIRD-PARTY-NOTICES.txt"), FileAccess.WRITE)
	if notices == null:
		quit(1)
		return
	notices.store_string("Godot Engine component copyright and license metadata\n\n")
	notices.store_string(JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\n")
	var licenses = Engine.get_license_info()
	var names = licenses.keys()
	names.sort()
	for name in names:
		notices.store_string("\n" + name + "\n" + "=".repeat(60) + "\n" + licenses[name] + "\n")
	notices.close()
	print("Engine notices written.")
	quit(0)
