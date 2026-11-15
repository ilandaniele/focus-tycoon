class_name TestCase
extends RefCounted

var failures: Array[String] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail("expected true. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail("expected false. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_number(actual) and _is_number(expected)):
		fail("type mismatch: got %s (%s), expected %s (%s). %s" % [actual, type_string(typeof(actual)), expected, type_string(typeof(expected)), message])
	elif actual != expected:
		fail("got %s, expected %s. %s" % [actual, expected, message])


func assert_near(actual: float, expected: float, epsilon: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		fail("got %f, expected %f ± %f. %s" % [actual, expected, epsilon, message])


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
