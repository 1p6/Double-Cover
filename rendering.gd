extends Node

func onViewportChange():
	$"World A".size = get_viewport().size
	$"World B".size = get_viewport().size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	onViewportChange()
	get_viewport().size_changed.connect(onViewportChange)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	($Quaternion/ColorRect.material as ShaderMaterial).set_shader_parameter('deltaTime', delta);
	pass
