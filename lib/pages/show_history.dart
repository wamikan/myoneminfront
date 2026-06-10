import 'package:flutter/material.dart';

// 計測履歴を表すクラス（外部から参照できるようにクラス外に定義）
class ResultItem {
  ResultItem(this.targetDuration, this.actualDuration);
  final Duration targetDuration;
  final Duration actualDuration;
}

class ShowHistoryPage extends StatefulWidget {
  // コンストラクタを修正：必要な引数を受け取るように変更
  const ShowHistoryPage({
    super.key, 
    required this.title,
    required this.targetDuration,
    required this.histories,
  });

  final String title;
  final Duration targetDuration;       // 追加
  final List<ResultItem> histories;    // 追加

  @override
  State<ShowHistoryPage> createState() => _ShowHistoryPageState();
}

class _ShowHistoryPageState extends State<ShowHistoryPage> {
  // サンプルデータは削除し、widgetから受け取ったデータを使うように変更
  
  String formatDuration(Duration duration) {
    String toTwoDigits(int n) => n.toString().padLeft(2, "0");
    String ho = toTwoDigits(duration.inHours.remainder(60).abs());
    String min = toTwoDigits(duration.inMinutes.remainder(60).abs());
    String sec = toTwoDigits(duration.inSeconds.remainder(60).abs());
    return (duration.inSeconds < 0) ? "-$ho:$min:$sec" : " $ho:$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    // 履歴データがない場合のハンドリング（空の場合はwidget.historiesをそのまま使う）
    final displayHistories = widget.histories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "死守す一分",
          style: TextStyle(
            fontFamily: "NotoSansJP",
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 画像パスは環境に合わせて調整してください
        flexibleSpace: Container(color: Colors.deepPurple[100]), 
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              "「${widget.title}」の計測履歴：", // タイトルを動的に表示
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30.0),
            ),
            SizedBox(height: 10),
            // ヘッダー部分
            Container(
              color: Colors.grey[700],
              child: Container(
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text("回前", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Text("目標時間", style: TextStyle(fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text("計測時間", style: TextStyle(fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text("目標-計測", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 3),
                  ],
                ),
              ),
            ),
            // リスト部分
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(), // スクロール競合防止
              itemCount: displayHistories.length,
              itemBuilder: (BuildContext context, index) {
                // 新しい履歴が上に来るように逆順で取得する場合の例
                // final item = displayHistories[displayHistories.length - 1 - index];
                final item = displayHistories[index];

                Duration target = item.targetDuration;
                Duration actual = item.actualDuration;
                Duration diff = target - actual;
                
                return Container(
                  color: Colors.grey[700],
                  child: Container(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          (index + 1).toString().padLeft(3, "0"), // インデックス表示
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 8),
                        Text(formatDuration(target), style: TextStyle(fontSize: 20)),
                        Spacer(),
                        Text(formatDuration(actual), style: TextStyle(fontSize: 20)),
                        Spacer(),
                        Text(
                          formatDuration(diff),
                          style: TextStyle(
                            fontSize: 20,
                            color: diff.inSeconds < 0 ? Colors.red : Colors.black,
                          ),
                        ),
                        SizedBox(width: 3),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 戻るボタンとして機能させる
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "戻る",
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}