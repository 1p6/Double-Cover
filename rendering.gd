extends Node
class_name Renderer

var isOnBSide : bool = false
signal onSideChange(newSide: bool)

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


func _on_side_var_updater_timeout() -> void:
	var vp: SubViewport = $Quaternion;
	var img = vp.get_texture().get_image();
	var center = img.get_pixel(img.get_width()/2, img.get_height()/4);
	var prevSide = isOnBSide
	isOnBSide = center.b > 0.5;
	if prevSide != isOnBSide: onSideChange.emit(isOnBSide)
	$Label.text = "Side: " + ("B" if isOnBSide else "A");
