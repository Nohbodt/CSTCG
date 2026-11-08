class_name PackGesture
extends RefCounted
## Monotonic, presentation-only tear progress. No clock, economy or random state.

const DRAG_THRESHOLD = 8.0
var held = false
var dragging = false
var progress = 0.0
var start = Vector2.ZERO
var start_progress = 0.0
var span = 1.0

func press(position: Vector2, distance: float) -> bool:
	if held:
		return false
	held = true
	dragging = false
	start = position
	start_progress = progress
	span = maxf(48.0, distance)
	return true

func motion(position: Vector2) -> bool:
	if not held:
		return false
	var began = not dragging and position.distance_to(start) >= DRAG_THRESHOLD
	if began:
		dragging = true
	if dragging:
		progress = maxf(progress, clampf(start_progress + (position.x - start.x) / span, 0.0, 1.0))
	return began

func release(position: Vector2) -> String:
	if not held:
		return ""
	motion(position)
	var result = "open" if not dragging else ("finish" if progress >= 0.995 else "pause")
	held = false
	dragging = false
	return result

func cancel() -> void:
	held = false
	dragging = false

func reset() -> void:
	cancel()
	progress = 0.0
