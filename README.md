# ntcir_slide

## 周囲のスライドのスコアを重みに応じて統合

## ファイル構成
- slide.rb  : main.pyで計算された結果(result/に保存)を用いて、前後スライドを重み付き統合
    - 基本的にコレを利用する
    - slide_asr.rb : asr用の、前後スライド統合 (正規表現のみ違う)
    - slide_inspect.rb : 中の情報の詳細をみる

## 作業フロー
1. main.pyによって計算された、result/を参照
2. result/にたいして`ruby slide.rb`を実行。
3. map値を計算
