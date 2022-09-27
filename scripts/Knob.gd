extends MeshInstance

export var hovered_mat: Material
export var default_mat: Material
export var value = 0.0

func on_interact_move(delta):
	var speed = 2.0
	value += delta.x * speed
	value -= delta.y * speed

func _process(_delta):
	rotation.z = -value

func on_interact_start():
	return true
	
func on_hover_start():
	set_surface_material(0, hovered_mat)

func on_hover_end():
	set_surface_material(0, default_mat)
