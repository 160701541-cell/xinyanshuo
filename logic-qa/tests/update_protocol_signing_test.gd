extends SceneTree
## REAL production update_protocol.gd with real production Python/OpenSSL sign format.
## The RSA key is TEMPORARY test-only; production APK must reject it.
const Protocol = preload("res://scripts/update_protocol.gd")
const Channel = preload("res://scripts/update_channel.gd")
var errors: Array[String] = []

func check(ok: bool, why: String) -> void:
	if not ok:
		errors.append(why)
		printerr("SIGNED_OTA_FAIL: ", why)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manifest_path: String = OS.get_environment("CANGLAN_QA_MANIFEST_PATH")
	var public_key_path: String = OS.get_environment("CANGLAN_QA_TEST_PUBLIC_KEY")
	var pack_path: String = OS.get_environment("CANGLAN_QA_PCK_PATH")
	if manifest_path.is_empty() or public_key_path.is_empty() or pack_path.is_empty():
		printerr("SIGNED_OTA_FAIL: missing signed manifest/test key/real PCK")
		quit(2)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		printerr("SIGNED_OTA_FAIL: invalid signed manifest")
		quit(3)
		return
	var manifest: Dictionary = parsed
	var pubkey: String = FileAccess.get_file_as_string(public_key_path)
	check(manifest.get("revision", 0) == 177, "revision must be 177, NOT obsolete 168")
	check(manifest.get("minimum_android_code", 0) == 1176, "tiny OTA must be APK176+ only, never legacy bases")
	check(manifest.get("maximum_android_code", 0) >= 1176, "old APK176 excluded by maximum code")
	check(1176 - 1000 == 176 and int(manifest.get("revision", 0)) > 176, "APK176 immutable revision floor not passed")
	check(Protocol.safe_manifest(manifest, 1176, pubkey), "production Godot Crypto must verify Python/OpenSSL signing")
	check(not Protocol.safe_manifest(manifest, 1165, pubkey), "older APK165 must reject a tiny noncumulative PCK177")
	check(Protocol.matches_pack(manifest, pack_path, 1176, pubkey), "signed sha256 and PCK bytes must match")
	check(not Protocol.safe_manifest(manifest, 1176, Channel.PUBLIC_KEY_PEM),
		"release APK key MUST refuse a temporary test-only signature")
	var changed: Dictionary = manifest.duplicate(true)
	changed["revision"] = 168
	check(not Protocol.safe_manifest(changed, 1176, pubkey), "changing signed revision invalidates RSA")
	changed = manifest.duplicate(true)
	changed["sha256"] = "f".repeat(64)
	check(not Protocol.safe_manifest(changed, 1176, pubkey), "changing signed PCK digest invalidates RSA")
	changed = manifest.duplicate(true)
	changed["pack_url"] = "http://example.test/malicious.pck"
	check(not Protocol.safe_manifest(changed, 1176, pubkey), "HTTP URL rejected")
	changed = manifest.duplicate(true)
	changed["minimum_android_code"] = 1177
	check(not Protocol.safe_manifest(changed, 1176, pubkey), "min APK version forged")
	check(Protocol.pack_path(manifest).begins_with("user://canglan_updates/pack_177_"),
		"immutable update pack path derivation")
	var corrupted_path := "user://canglan_temp_corrupt_ota177.pck"
	var altered: PackedByteArray = FileAccess.get_file_as_bytes(pack_path)
	if altered.is_empty():
		check(false, "actual PCK empty")
	else:
		altered.append(42)
		var written: FileAccess = FileAccess.open(corrupted_path, FileAccess.WRITE)
		if written == null:
			check(false, "cannot stage malformed candidate")
		else:
			written.store_buffer(altered)
			written.close()
			check(not Protocol.matches_pack(manifest, corrupted_path, 1176, pubkey),
				"even one extra byte must block PCK")
		DirAccess.remove_absolute(corrupted_path)
	check(ProjectSettings.load_resource_pack(pack_path, true), "a real test PCK must mount")
	check(FileAccess.file_exists("res://scripts/touch_look_router_ota177.gd"), "versioned code present after pack mount")
	print("CANG LAN PRODUCTION SIGNED OTA PROTOCOL TEST errors=", errors.size())
	if errors.is_empty():
		print("PASS REAL PYTHON-OPENSSL GODOT OTA SIGNATURE + PCK BYTES (EPHEMERAL KEY ONLY)")
		quit(0)
	else:
		quit(1)
