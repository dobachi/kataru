extends Node2D
## S1: タイルマップ表示＋プレイヤーのグリッド移動＋カメラ追従。
## マップは当面ここでASCIIから生成する（S2で data/*.json 読み込みへ置き換え）。

const TILE_SIZE := 16  # SNES級を想定した16pxタイル基準（S1は色塗りプレースホルダ）

# 古風RPG風のデモマップ。'#'=壁 '.'=床 '@'=プレイヤー初期位置
const DEMO_MAP := [
	"####################",
	"#..................#",
	"#..####....####....#",
	"#..#..........#....#",
	"#.....@.......#....#",
	"#..#..........#....#",
	"#..####....####....#",
	"#..................#",
	"#....######........#",
	"#..................#",
	"#..................#",
	"####################",
]

func _ready() -> void:
	var map := _build_map(DEMO_MAP)

	var renderer := MapRenderer.new()
	renderer.setup(map, TILE_SIZE)
	add_child(renderer)

	var player := Player.new()
	player.setup(map, map.player_start, TILE_SIZE)
	add_child(player)

	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	# マップ外を映さないよう端で止める
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map.width * TILE_SIZE
	cam.limit_bottom = map.height * TILE_SIZE
	player.add_child(cam)
	cam.make_current()

## ASCII行配列から WorldMap を生成する（S1暫定。S2で正式な記法→変換へ）。
func _build_map(ascii: Array) -> WorldMap:
	var rows: Array = []
	var start := Vector2i(1, 1)
	for y in ascii.size():
		var line: String = ascii[y]
		var row: Array = []
		for x in line.length():
			var ch := line[x]
			row.append(TileTypes.WALL if ch == "#" else TileTypes.FLOOR)
			if ch == "@":
				start = Vector2i(x, y)
		rows.append(row)
	var map := WorldMap.new(rows)
	map.player_start = start
	return map
