extends SceneTree

const Gesture = preload("res://scripts/presentation/pack_gesture.gd")
var failures = 0
var checks = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("GESTURE FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var gesture = Gesture.new()
	check(gesture.press(Vector2(10, 20), 100), "press begins one gesture")
	check(not gesture.press(Vector2(50, 20), 100), "a second pointer cannot steal the gesture")
	gesture.motion(Vector2(14, 22))
	check(gesture.release(Vector2(14, 22)) == "open", "normal click with small hand jitter opens")
	check(gesture.release(Vector2(14, 22)).is_empty(), "duplicate release cannot open twice")
	gesture.reset()
	gesture.press(Vector2.ZERO, 100)
	check(gesture.motion(Vector2(40, 0)), "deliberate horizontal motion begins a tear")
	check(is_equal_approx(gesture.progress, 0.4), "partial drag follows distance")
	gesture.motion(Vector2(15, 0))
	check(is_equal_approx(gesture.progress, 0.4), "moving backwards cannot reseal the pack")
	check(gesture.release(Vector2(15, 0)) == "pause", "release preserves a partial tear")
	gesture.press(Vector2(20, 0), 100)
	gesture.motion(Vector2(55, 0))
	check(is_equal_approx(gesture.progress, 0.75), "a later drag continues from the retained tear")
	gesture.cancel()
	check(not gesture.held and is_equal_approx(gesture.progress, 0.75), "focus cancellation preserves progress")
	check(gesture.release(Vector2(500, 0)).is_empty(), "late release after cancellation does nothing")
	gesture.press(Vector2.ZERO, 100)
	check(gesture.release(Vector2.ZERO) == "open", "click can finish a previously paused tear")
	gesture.press(Vector2.ZERO, 100)
	gesture.motion(Vector2(35, 0))
	check(gesture.release(Vector2(35, 0)) == "finish" and gesture.progress == 1.0, "remaining swipe completes once at the end")
	gesture.reset()
	gesture.press(Vector2.ZERO, 100)
	gesture.motion(Vector2(-30, 0))
	check(gesture.release(Vector2(-30, 0)) == "pause" and gesture.progress == 0.0, "wrong-way drag does not turn into a click")
	gesture.reset()
	check(not gesture.held and not gesture.dragging and gesture.progress == 0, "next pack starts with a sealed gesture")
	print("CSTCG_GESTURE_TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
