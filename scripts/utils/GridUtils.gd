class_name GridUtils
extends RefCounted

# Isometric Grid Utilities

const TILE_SIZE: float = 2.0
const TILE_HEIGHT: float = 1.0 # Vertical step size

## Converts Grid Coordinates (Vector3i) to World Position (Vector3)
static func grid_to_world(grid_pos: Vector3i) -> Vector3:
	return Vector3(
		grid_pos.x * TILE_SIZE,
		grid_pos.y * TILE_HEIGHT,
		grid_pos.z * TILE_SIZE
	)

## Converts World Position (Vector3) to Grid Coordinates (Vector3i)
static func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		round(world_pos.x / TILE_SIZE),
		round(world_pos.y / TILE_HEIGHT),
		round(world_pos.z / TILE_SIZE)
	)

## Calculates Manhattan distance between two grid points (ignoring height for movement range usually)
static func get_distance(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.z - b.z)
