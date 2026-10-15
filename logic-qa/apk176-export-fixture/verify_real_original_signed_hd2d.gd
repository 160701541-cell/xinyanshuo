extends SceneTree
## Validation must use the *permanent* baked APK176 public key, never an
## ephemeral QA key. No unsigned candidate may pass.
const Protocol = preload("res://scripts/update_protocol.gd")
const Channel = preload("res://scripts/update_channel.gd")

func _initialize() -> void:
	var manifest_file := OS.get_environment("CANGLAN_OTA_SIGNED_MANIFEST")
	var pack := OS.get_environment("CANGLAN_QA_PCK_PATH")
	if manifest_file.is_empty() or pack.is_empty():
		printerr("BLOCKED: production signed OTA manifest/PCK absent")
		quit(2)
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_file))
	if not (raw is Dictionary):
		printerr("BLOCKED: invalid signed OTA manifest")
		quit(3)
		return
	var manifest: Dictionary = raw
	if int(manifest.get("revision",0)) < 177:
		printerr("BLOCKED: APK176 revision floor")
		quit(4)
		return
	if not Protocol.safe_manifest(manifest, 1176, Channel.PUBLIC_KEY_PEM):
		printerr("BLOCKED: actual APK176 RSA key rejected signed manifest")
		quit(5)
		return
	if not Protocol.matches_pack(manifest, pack, 1176, Channel.PUBLIC_KEY_PEM):
		printerr("BLOCKED: signed PCK bytes mismatch")
		quit(6)
		return
	if not ProjectSettings.load_resource_pack(pack, true):
		printerr("BLOCKED: signed PCK refused to mount")
		quit(7)
		return
	var main := ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	if main == null:
		printerr("BLOCKED: OTA breaks APK176 original main scene path")
		quit(8)
		return
	print("PASS_APK176_PERMANENT_RSA_PCK_AND_CANONICAL_MAIN_SCENE (NOT PHONE QA)")
	quit(0)
