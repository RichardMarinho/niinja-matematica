extends Node2D

var _random := RandomNumberGenerator.new()
var _crack_lines: Array[PackedVector2Array] = []


func play() -> void:
	_random.randomize()
	_build_cracks()
	queue_redraw()
	var fade := create_tween()
	fade.tween_interval(2.2)
	fade.tween_property(self, "modulate:a", 0.0, 1.15)
	fade.tween_callback(queue_free)


func _build_cracks() -> void:
	_crack_lines.clear()
	var ray_count := _random.randi_range(8, 10)
	for ray_index in range(ray_count):
		var angle := TAU * float(ray_index) / float(ray_count) + _random.randf_range(-0.18, 0.18)
		var segment_count := _random.randi_range(3, 5)
		var ray_length := _random.randf_range(45.0, 78.0)
		var points := PackedVector2Array([Vector2.ZERO])
		for segment_index in range(1, segment_count + 1):
			var direction := Vector2.RIGHT.rotated(angle + _random.randf_range(-0.13, 0.13))
			var point := direction * ray_length * float(segment_index) / float(segment_count)
			if segment_index < segment_count:
				point += Vector2(_random.randf_range(-5.0, 5.0), _random.randf_range(-5.0, 5.0))
			points.append(point)
		_crack_lines.append(points)

		if segment_count > 2 and _random.randf() < 0.8:
			var branch_start := points[_random.randi_range(1, segment_count - 1)]
			var branch_angle := angle + _random.randf_range(-0.95, 0.95)
			var branch_length := _random.randf_range(17.0, 34.0)
			var branch := PackedVector2Array([
				branch_start,
				branch_start + Vector2.RIGHT.rotated(branch_angle) * branch_length * 0.52,
				branch_start + Vector2.RIGHT.rotated(branch_angle + _random.randf_range(-0.18, 0.18)) * branch_length,
			])
			_crack_lines.append(branch)


func _draw() -> void:
	for points in _crack_lines:
		draw_polyline(points, Color(0.12, 0.045, 0.02, 0.9), 3.2, true)
		draw_polyline(points, Color(0.78, 0.52, 0.32, 0.92), 1.35, true)
	draw_circle(Vector2.ZERO, 4.5, Color(0.12, 0.045, 0.02, 0.85))
	draw_circle(Vector2.ZERO, 2.0, Color(0.86, 0.62, 0.39, 0.95))
