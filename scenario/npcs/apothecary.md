---
id: apothecary
name: 薬屋の店主
sprite: apothecary
---

## 会話 if=quest_herb:done
- 先日は助かったよ。よく効く薬ができそうだ。

## 会話 if=quest_herb:collected set=quest_herb:done
- おお、薬草を採ってきてくれたか！ありがとう、助かるよ。

## 会話 if=quest_herb:started
- 薬草はまだかい？　東の森に生えているはずだよ。

## 会話 if=quest_herb:none
- いらっしゃい。……そうだ、東の森で薬草を採ってきてくれないか？
? 引き受ける set=quest_herb:started
- ありがとう、助かるよ。採れたら、また声をかけてくれ。
? 今はやめておく
- そうかい。気が向いたら、また来ておくれ。
