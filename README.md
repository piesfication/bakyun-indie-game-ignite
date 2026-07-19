# Bakyun

Bakyun adalah project game 2D Godot bernuansa visual novel dan arcade shooting. Pemain mengikuti Baku dan Yuna melalui menu cerita, misi, tutorial, dan mode endless. Di sisi gameplay, project ini berisi sistem crosshair/shooting, spawn musuh, meter skill, ultimate, kartu endless, peningkatan kemampuan, serta progres chapter yang terhubung dengan Dialogic.

Project ini dibuat dengan Godot 4.6 dan memakai plugin Dialogic untuk timeline dialog, karakter, choice, dan style textbox.

## Ringkasan Gameplay

- **Title screen** menjadi entry point game dan membuka alur ke menu level.
- **Mission/Journey** menampilkan pilihan misi acak dari beberapa difficulty.
- **Combat level** memakai sistem spawn musuh, crosshair, player health, combo, bird strike, ultimate, dan win/lose sequence.
- **Story mode** memakai timeline Dialogic untuk chapter utama dan percabangan pilihan.
- **Tutorial** memakai timeline tutorial terpisah untuk mengenalkan mekanik.
- **Endless mode** memakai data kartu dari resource `.tres` untuk variasi run.
- **Basecamp** saat ini mengarah ke archive dan tempat fitur training bisa dilanjutkan.

## Cara Menjalankan

1. Install Godot 4.6 atau versi 4.x yang kompatibel.
2. Buka Godot Project Manager.
3. Import folder repository ini.
4. Pastikan plugin Dialogic aktif di `Project > Project Settings > Plugins`.
5. Jalankan project dari Godot editor.

Path Godot 4.6 yang dipakai di mesin ini:

```text
S:\@BIKIN GAMEEEEE\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe
```

Validasi cepat lewat terminal:

```powershell
& "S:\@BIKIN GAMEEEEE\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --quit
```

Scene utama sudah diatur di [project.godot](project.godot):

```ini
run/main_scene="uid://unffs1vlk3ih"
```

UID tersebut mengarah ke [scenes/menus/title_screen.tscn](scenes/menus/title_screen.tscn).

## Kontrol dan Shortcut

- Klik mouse di title screen untuk masuk ke game.
- Klik ikon/pilihan UI untuk navigasi menu.
- `Space` dipakai untuk action `ulti` dan juga termasuk action default Dialogic.
- `Tab` terdaftar sebagai action `switch`.
- `X`, `Space`, klik kiri, dan tombol joypad utama terdaftar sebagai action `dialogic_default_action`.
- `F3` dari title screen membuka [scenes/debug/enhancement_debug.tscn](scenes/debug/enhancement_debug.tscn) saat playtest dari editor.

## Struktur Folder

| Path | Isi |
| --- | --- |
| `addons/dialogic/` | Plugin Dialogic yang dipakai project. |
| `assets/` | Sprite, UI, font, background, karakter, musuh, kartu, archive, dan asset visual lain. |
| `data/cards/` | Resource kartu endless (`.tres`) yang dipisahkan dari aset visual. |
| `dialogue/characters/` | Resource karakter Dialogic (`.dch`). |
| `dialogue/story/` | Timeline Dialogic untuk prologue dan cerita utama. |
| `dialogue/tutorials/` | Timeline Dialogic untuk tutorial. |
| `music/` | BGM dan SFX, termasuk subfolder `bgm/menu`, `bgm/level`, `bgm/story`, `bgm/hitoribocchi`, `sfx/shooting`, `sfx/glitch`, dan `sfx/etc`. |
| `resources/audio/` | Konfigurasi audio bus Godot. |
| `scenes/core/` | Scene global untuk loading, transition, music, dan world audio. |
| `scenes/gameplay/` | Level, enemy, projectile, dan komponen gameplay. |
| `scenes/menus/` | Title screen, map, level menu, story menu, archive, dan endless. |
| `scenes/story/` | Scene chapter dan percakapan story. |
| `scenes/ui/` | Komponen UI yang dapat dipakai ulang. |
| `scripts/autoload/` | State dan manager global project. |
| `scripts/gameplay/` | Logic level, enemy, projectile, player, meter, dan combat. |
| `scripts/story/` | Logic chapter, dialogue UI, dan story sequence. |
| `scripts/ui/` | Logic komponen UI dan menu. |
| `shaders/` | Shader CRT, checkerboard, level menu, dan tutorial. |
| `themes/` | Theme, label settings, dan layout textbox Dialogic. |

## Scene Penting

| Scene | Fungsi |
| --- | --- |
| [scenes/menus/title_screen.tscn](scenes/menus/title_screen.tscn) | Scene awal project. Menampilkan title, intro card, character click area, dan navigasi awal. |
| [scenes/core/loading_screen.tscn](scenes/core/loading_screen.tscn) | Scene loading perantara. Target scene diatur lewat `LoadingManager`. |
| [scenes/menus/map.tscn](scenes/menus/map.tscn) | World map dengan lokasi tutorial, journey, endless, dan basecamp. |
| [scenes/menus/level_menu.tscn](scenes/menus/level_menu.tscn) | Menu misi yang memilih 3 level acak dari pool easy/medium/hard. |
| [scenes/gameplay/levels/main.tscn](scenes/gameplay/levels/main.tscn) | Level combat utama. |
| [scenes/gameplay/levels/main_easy.tscn](scenes/gameplay/levels/main_easy.tscn) | Varian level easy. |
| [scenes/gameplay/levels/main_hard.tscn](scenes/gameplay/levels/main_hard.tscn) | Varian level hard. |
| [scenes/gameplay/levels/main_boss.tscn](scenes/gameplay/levels/main_boss.tscn) | Level boss utama sebelum cabang boss lanjutan. |
| [scenes/gameplay/levels/main_yuokai.tscn](scenes/gameplay/levels/main_yuokai.tscn) | Cabang level boss Yuokai. |
| [scenes/gameplay/levels/main_bakumono.tscn](scenes/gameplay/levels/main_bakumono.tscn) | Cabang level boss Bakumono. |
| [scenes/gameplay/levels/tutorial.tscn](scenes/gameplay/levels/tutorial.tscn) | Mode tutorial. |
| [scenes/menus/story_menu.tscn](scenes/menus/story_menu.tscn) | Menu chapter/story. |
| [scenes/menus/endless/endless_menu.tscn](scenes/menus/endless/endless_menu.tscn) | Menu endless. |
| [scenes/menus/archive.tscn](scenes/menus/archive.tscn) | Archive/memories. |
| [scenes/debug/enhancement_debug.tscn](scenes/debug/enhancement_debug.tscn) | Debug scene untuk pilihan enhancement. |

## Autoload

Autoload utama didefinisikan di [project.godot](project.godot):

| Autoload | Path | Tanggung Jawab |
| --- | --- | --- |
| `LevelData` | [scripts/autoload/level_data.gd](scripts/autoload/level_data.gd) | Pool misi dan pemilihan level acak berdasarkan difficulty. |
| `LoadingDialogue` | [scripts/autoload/loading_dialogue.gd](scripts/autoload/loading_dialogue.gd) | Dialog/loading flavor text. |
| `LoadingManager` | [scripts/autoload/loading_manager.gd](scripts/autoload/loading_manager.gd) | Menyimpan target scene dan state pembukaan title. |
| `Transition` | [scenes/core/transition.tscn](scenes/core/transition.tscn) | Fade out/fade in antar scene. |
| `MusicManager` | [scenes/core/music_manager.tscn](scenes/core/music_manager.tscn) | Manager musik. |
| `Dialogic` | `addons/dialogic` | Sistem dialog, timeline, karakter, dan choice. |
| `StoryProgress` | [scripts/autoload/story_progress.gd](scripts/autoload/story_progress.gd) | Save progres chapter, jumlah mission win, dan variable Dialogic. |
| `AudioManager` | [scenes/core/world_audio_manager.tscn](scenes/core/world_audio_manager.tscn) | Playback BGM/SFX global. |
| `Current` | [scripts/autoload/current_play.gd](scripts/autoload/current_play.gd) | Menyimpan mode yang sedang dimainkan. |
| `CardDatabase` | [scripts/autoload/card_database.gd](scripts/autoload/card_database.gd) | Memuat resource kartu endless dari folder kartu. |
| `EnhancementManager` | [scripts/autoload/enhancement_manager.gd](scripts/autoload/enhancement_manager.gd) | Save dan query pilihan enhancement per tier. |

## Alur Navigasi

Alur normal project saat ini:

```text
title_screen
  -> loading_screen
  -> level_menu
  -> combat level
```

Map juga sudah menyiapkan alur:

```text
map
  -> tutorial
  -> level_menu / story_menu
  -> endless_menu
  -> archive
```

Transisi antar scene umumnya memakai pola:

```gdscript
LoadingManager.set_target_scene("res://scenes/target.tscn")
await Transition.fade_out()
get_tree().change_scene_to_file("res://scenes/core/loading_screen.tscn")
await Transition.fade_in()
```

## Sistem Combat

Combat utama berada di [scripts/gameplay/levels/main.gd](scripts/gameplay/levels/main.gd) dan [scenes/gameplay/levels/main.tscn](scenes/gameplay/levels/main.tscn). Beberapa komponen penting:

- `EnemyContainer` menjadi parent musuh yang di-spawn.
- `Player` mengelola state pemain dan sinyal `died`.
- `Crosshair` mengelola aim/shoot.
- `UIMahouMeter` dan `UIKoisuruMeter` mengelola resource/ultimate.
- `CardUI` menampilkan kartu untuk mode/fitur kartu.
- `LevelEndOverlay` menampilkan hasil akhir dan combo.
- `BirdStrike` dan `BirdStrikeAlert` menjadi hazard/event level.

Parameter seperti `max_enemies`, `spawn_interval`, `level_duration_seconds`, durasi intro, durasi win/lose, dan peluang bird strike diekspos sebagai export variable sehingga bisa diatur dari editor.

## Story dan Progress

Story memakai Dialogic:

- Karakter ada di `dialogue/characters/*.dch`.
- Prologue dan timeline cerita utama ada di `dialogue/story/*.dtl`.
- Timeline tutorial ada di `dialogue/tutorials/*.dtl`.
- Style textbox ada di `themes/dialogic/style_1.tres` dan folder `themes/dialogic/visual_novel_textbox/`.

[scripts/autoload/story_progress.gd](scripts/autoload/story_progress.gd) menyimpan progres ke:

```text
user://story_progress.cfg
```

Aturan progres saat ini:

- Chapter maksimal: 5.
- Chapter 1 selalu terbuka.
- Chapter berikutnya membutuhkan progres sesuai state.
- Mission win yang dibutuhkan per chapter: 3.
- Variable Dialogic ikut disimpan saat chapter selesai.

## Level Data

[scripts/autoload/level_data.gd](scripts/autoload/level_data.gd) menyimpan daftar misi dengan format dictionary:

```gdscript
{
	"title": "Totally Normal Tuesday",
	"difficulty": "easy",
	"line_baku": "...",
	"line_yuna": "..."
}
```

Difficulty yang tersedia:

- `easy`
- `medium`
- `hard`

Menu level memilih 3 ikon aktif secara acak, lalu mengisi masing-masing dengan data level random dari pool difficulty.

## Endless dan Kartu

Kartu menggunakan resource [scripts/resources/card_data.gd](scripts/resources/card_data.gd) dengan field:

- `card_name`
- `front_texture`
- `back_texture`
- `category`

[scripts/autoload/card_database.gd](scripts/autoload/card_database.gd) memuat semua `.tres` dari:

- `data/cards/baku/`
- `data/cards/boss/`
- `data/cards/crosshair/`
- `data/cards/danger/`
- `data/cards/kizuna/`
- `data/cards/koisuru/`
- `data/cards/spawn/`
- `data/cards/yuna/`

## Enhancement

[scripts/autoload/enhancement_manager.gd](scripts/autoload/enhancement_manager.gd) menyimpan pilihan enhancement ke:

```text
user://enhancements.cfg
```

Tier yang tersedia adalah 1 sampai 5. Pilihan yang dikenali:

- `none`
- `overdrive`
- `pierce`
- `chain`
- `nova`

Beberapa efek yang sudah tersedia di manager:

- Overdrive dapat memberi heal atau mengisi combo random.
- Pierce dapat memberi bonus damage terhadap enemy slow dan spawn secondary burst.
- Chain dapat menambah bounce, memprioritaskan enemy slow, dan memberi instant kill pada hit terakhir.
- Nova dapat membagi damage dan memperpanjang durasi slow.

## Catatan Development

- File autosave `*.tmp` lama sudah dibersihkan dari folder `scenes/` pada refactor struktur pertama.
- Project ini sangat asset-heavy. Saat review perubahan, pisahkan perubahan script/scene dari perubahan import asset agar diff lebih mudah dibaca.
- Beberapa asset audio sudah berada di `music/bgm/...`, tapi masih ada referensi lama ke `res://assets/music/...` di script/scene. Jika BGM menu tidak muncul, cek ulang path audio tersebut.
- File `assets/rstk/Ristek_Gamedev (2).png` terdeteksi bukan PNG valid oleh Godot 4.6. Game tetap memakai splash bawaan, tetapi aset ini perlu diganti sebelum build publik.
- Beberapa string di file terlihat mengalami mojibake seperti `â€”` atau `â€™`. Jika teks tampil aneh di game, cek encoding sumber teksnya.
- Jangan edit `project.godot` manual kecuali perlu. Untuk setting engine, lebih aman lewat Godot editor.
- File save berada di `user://`, jadi reset project folder tidak otomatis menghapus progres lokal pemain/editor.

## Lisensi

Repository ini menyertakan file [LICENSE](LICENSE). Pastikan lisensi asset pihak ketiga, musik, dan SFX juga sudah sesuai sebelum build publik.
