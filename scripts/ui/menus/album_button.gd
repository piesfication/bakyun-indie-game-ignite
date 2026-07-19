extends TextureButton

signal thumbnail_pressed(thumbnail)

func _pressed():
	thumbnail_pressed.emit(self)
	print
