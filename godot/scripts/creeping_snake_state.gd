## Animation and movement state for the snake of spell 35.
extends RefCounted

var node: Node2D
var phase := "away"
var elapsed := 0.0
var duration := 1.6
var offset := 0.0
var lift := 0.0
var horizontal_scale := 1.0
var wobble := 0.0
var fake_warning := false

var slide_from := 0.0
var slide_to := 0.0
var return_offset := 0.0
var previous_scale := 1.0
var previous_lift := 0.0
var bite_reason := ""


func _init(actor: Node2D) -> void:
	node = actor
