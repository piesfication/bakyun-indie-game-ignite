class_name CurrentPlay
extends Node

# Target scene path yang akan dituju setelah loading screen
var current_mode_played: String = ""

func getcurrentmode():
	return current_mode_played
	
func setcurrentmode(mode):
	current_mode_played = mode
