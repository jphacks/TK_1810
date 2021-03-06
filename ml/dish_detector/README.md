# PyTorch-YOLOv3

Minimal implementation of YOLOv3 in PyTorch.

This model is based on [PyTorch-YOLOv3](https://github.com/eriklindernoren/PyTorch-YOLOv3)

## 目的

写真のインスタ映え度において，食べ物の配置やカメラ角度，専有面積といった要素が重要であると考えられるため，それを推定する．

## 背景

当初は食べ物の領域を画像処理の手法で検出しようと考えた．例えばお皿の輪郭が検出ができれば，位置や面積はもちろん，実際の皿の形を真円と仮定することでカメラ角度も算出できる．しかしOpenCVの楕円検出や，色特徴のヒストグラムを用いるような単純な方法では難しいことがわかった.


## 手法

そこで，物体検出モデルを組むことにした．最初は食べ物の物体検出（bbox + 料理カテゴリ）をしようと考えたが，データセットがないことが問題となった．

そこで試しにMSCOCOで訓練されたYOLOv3を動かしてみたところ，`bowl`クラスが比較的お皿を拾ってくれることがわかった．よって，これをファインチューニングすることで，食べ物でなく画像中のお皿を検出するモデルをつくることにした．

### データ・セット
データセットはインスタグラムから集めた主にラーメンとオムライスの画像約210枚をアノテーションし，150(train)+60(val)とした．
