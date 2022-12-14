extends "res://scripts/animation/FiniteProceduralAnimation.gd"

var start: Transform
var destination: Transform

func _init(d: Transform):
	destination = d

func on_start():
	start = target.transform

func evaluate():
	target.transform = start.interpolate_with(destination, progress())

func on_finish():
	Util.enable_colliders(target)
