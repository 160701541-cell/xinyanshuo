extends RefCounted
class_name CanglanUpdateProtocol
## A downloaded PCK can execute code: NEVER mount based only on HTTP or a
## checksummed JSON. Verify a release signature with the immutable APK key.
const SCHEMA: int = 1
const MAX_PACK_BYTES: int = 536870912 # 512 MiB safety limit.
const MAX_NOTES_CHARS: int = 256
const Channel = preload("res://scripts/update_channel.gd")

static func payload(data: Dictionary) -> String:
	return "canglan-pck-v1\n%d\n%s\n%d\n%d\n%d\n%s\n%d\n%s\n%s\n" % [
		int(data.get("schema", -1)),
		String(data.get("channel", "")),
		int(data.get("revision", -1)),
		int(data.get("minimum_android_code", -1)),
		int(data.get("maximum_android_code", -1)),
		String(data.get("sha256", "")),
		int(data.get("size_bytes", -1)),
		String(data.get("pack_url", "")),
		String(data.get("notes", ""))
	]

static func is_valid_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for i in range(value.length()):
		if not "0123456789abcdef".contains(value.substr(i, 1)):
			return false
	return true

static func safe_manifest(data: Dictionary, binary_code: int, public_key_pem: String) -> bool:
	if public_key_pem.is_empty() or data.size() < 9:
		return false
	if int(data.get("schema", -1)) != SCHEMA or String(data.get("channel", "")) != Channel.CHANNEL:
		return false
	var revision: int = int(data.get("revision", 0))
	var min_code: int = int(data.get("minimum_android_code", 0))
	var max_code: int = int(data.get("maximum_android_code", 0))
	var total: int = int(data.get("size_bytes", 0))
	var url: String = String(data.get("pack_url", ""))
	var sha: String = String(data.get("sha256", ""))
	var notes: String = String(data.get("notes", ""))
	if revision < 1 or min_code < 1 or max_code < min_code:
		return false
	if binary_code < min_code or binary_code > max_code:
		return false
	if total < 512 or total > MAX_PACK_BYTES or not is_valid_sha256(sha):
		return false
	if notes.length() > MAX_NOTES_CHARS:
		return false
	if not url.begins_with("https://") or url.length() > 2048 or url.contains(" ") or url.contains("\n"):
		return false
	var authority: String = url.substr(8).get_slice("/", 0)
	if authority.is_empty() or authority.contains("@") or authority.contains("#") or authority.contains("\\"):
		return false
	var signature_text: String = String(data.get("signature", ""))
	if signature_text.length() < 128 or signature_text.length() > 1024:
		return false
	var signature: PackedByteArray = Marshalls.base64_to_raw(signature_text)
	if signature.size() < 256:
		return false
	var key := CryptoKey.new()
	if key.load_from_string(public_key_pem, true) != OK or not key.is_public_only():
		return false
	return Crypto.new().verify(
		HashingContext.HASH_SHA256,
		payload(data).sha256_buffer(),
		signature, key
	)

static func pack_path(data: Dictionary) -> String:
	# active.json is locally writable: sanitize BEFORE constructing ANY path.
	if not is_valid_sha256(String(data.get("sha256", ""))) or int(data.get("revision", 0)) < 1:
		return ""
	return "user://canglan_updates/pack_%d_%s.pck" % [
		int(data.get("revision", 0)), String(data.get("sha256", "")).substr(0, 16)
	]

static func matches_pack(data: Dictionary, path: String, binary_code: int, public_key_pem: String) -> bool:
	if not safe_manifest(data, binary_code, public_key_pem):
		return false
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var size_ok: bool = file.get_length() == int(data["size_bytes"])
	file.close()
	if not size_ok:
		return false
	return FileAccess.get_sha256(path).to_lower() == String(data["sha256"])
