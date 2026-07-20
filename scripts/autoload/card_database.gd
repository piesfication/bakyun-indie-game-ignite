extends Node

const CARD_FOLDERS = [
	
	"res://data/cards/baku/",
	"res://data/cards/boss/",
	"res://data/cards/crosshair/",
	"res://data/cards/danger/",
	"res://data/cards/kizuna/",
	"res://data/cards/koisuru/",
	"res://data/cards/spawn/",
	"res://data/cards/yuna/"
	
]

var all_cards : Array[CardData] = []

func _ready():
	load_cards()
	print("Loaded ", all_cards.size(), " cards.")

func load_cards():

	all_cards.clear()

	for folder in CARD_FOLDERS:

		var dir = DirAccess.open(folder)

		if dir == null:
			push_warning("Folder tidak ditemukan: " + folder)
			continue

		dir.list_dir_begin()

		while true:

			var file = dir.get_next()

			if file == "":
				break

			if file.ends_with(".tres"):

				var card = load(folder + file)

				if card is CardData:
					all_cards.append(card)

		dir.list_dir_end()


func get_random_card() -> CardData:

	return all_cards.pick_random()
