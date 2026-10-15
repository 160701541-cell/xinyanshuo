extends RefCounted
## Deliberately broken APK-like base script. The OTA overlay must replace it.
## This fixture is NOT part of Canglan's real game and must never be released.
func begin(_index: int, _point: Vector2, _viewport: Vector2, _seconds: float = 0.0) -> bool:
	return false

func move(_index: int, _point: Vector2) -> Dictionary:
	return {}
