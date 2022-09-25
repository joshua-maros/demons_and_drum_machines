extends Reference

const HandState = preload("HandState.gd")
const RaycastResult = preload("RaycastResult.gd")

var hand_state: HandState
var last_hovered = null

func _init(h: HandState):
	hand_state = h

func physics_process(object: RaycastResult):
	if hand_state.is_holding_anything():
		start_hovering(null)
	elif object.collider != null:
		hover_collider(object.collider)
	else:
		start_hovering(null)

func hover_collider(collider):
	var new_hovered = collider.get_parent_spatial()
	if last_hovered != new_hovered:
		start_hovering(new_hovered)

func start_hovering(new_hovered):
	if new_hovered != null and new_hovered.has_method("on_hover_start"):
		new_hovered.on_hover_start()
	if last_hovered != null and last_hovered.has_method("on_hover_end"):
		last_hovered.on_hover_end()
	last_hovered = new_hovered