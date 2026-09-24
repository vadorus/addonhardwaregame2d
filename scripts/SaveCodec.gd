class_name SaveCodec
extends RefCounted

static func int64_to_json(value: int) -> String:
	return str(value)

static func int64_from_json(value: Variant, fallback: int) -> int:
	match typeof(value):
		TYPE_STRING:
			var text := str(value).strip_edges()
			return text.to_int() if text.is_valid_int() else fallback
		TYPE_INT, TYPE_FLOAT:
			return int(value)
		_:
			return fallback
