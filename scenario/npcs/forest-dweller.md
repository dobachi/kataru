---
id: forest-dweller
name: 森の住人
sprite: forest-dweller
---

## 会話 if=quest_herb:started|quest_herb:collected set=met_dweller:yes
- 薬草を探しているのかい？　この奥に生えているよ。

## 会話 if=quest_herb:done set=met_dweller:yes
- 薬は役に立ったかい？　それはよかった。

## 会話 set=met_dweller:yes
- おや、村の人かい。こんな森の奥まで珍しい。
- 日が暮れる前に、村へお戻り。
