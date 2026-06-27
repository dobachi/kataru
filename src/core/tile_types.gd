class_name TileTypes
## タイル種別の定義。S1ではプレースホルダ色で描画し、S2以降で実タイルへ置換する。

const FLOOR := 0
const WALL := 1

## S1暫定：種別に対応する塗り色。実タイルセット導入時に不要になる。
static func color_of(t: int) -> Color:
	match t:
		WALL:
			return Color(0.27, 0.24, 0.32)
		_:
			return Color(0.42, 0.62, 0.36)
