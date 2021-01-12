tool
extends KinematicBody

export var ori = 0 #setget setori
export(SpatialMaterial) var material #setget setori


func setori(o):
	if o is SpatialMaterial:
		material = o
		$block.material_override = material
	else:
		ori = o
		if ori == 0:
			$Anim.play("vertical")
		else:
			$Anim.play("horizontal")
	$block.material_override = material
func _on_Anim_tree_entered():
	setori(ori)
