import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// 通知サービスをインポート
import 'package:onemin_front/services/simple_notification_service.dart';
// 音やバイブレーションも連動させるためのインポート
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

// --- MeasurementPage クラス (StatefulWidget) ---
class MeasurementPage extends StatefulWidget {
  final String selectedTitle;
  final Duration duration;

  const MeasurementPage({
    super.key,
    required this.selectedTitle,
    required this.duration,
  });

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

// --- 秒針UIを実装するクラス ---
class ClockHand extends StatelessWidget {
  final double angle;
  final double length;
  final double thickness;
  final Color color;

  const ClockHand({
    super.key,
    required this.angle,
    required this.length,
    required this.thickness,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(width: thickness, height: length, color: color),
      ),
    );
  }
}

// --- 状態を管理するクラス ---
class _MeasurementPageState extends State<MeasurementPage> {
  late Timer _timer;
  int elapsedSeconds = 0;
  double angle = 0.0;
  bool isRunning = true;
  bool _hasNotified = false; // 通知済みかどうかのフラグ

  // ====== 修正ポイント：AudioPlayerをメンバ変数として保持 ======
  final player = AudioPlayer();
  final audioSourceUrl = 'alarm.mp3';
  // ============================================================

  int get remaining {
    final remain = widget.duration.inSeconds - elapsedSeconds;
    return remain > 0 ? remain : 0;
  }
  
  bool get isOver => elapsedSeconds > widget.duration.inSeconds;

  String get displayText => isOver ? "超過時間" : "予定終了まで：あと";
  Color get displayColor => isOver ? Colors.red : Colors.black;

  @override
  void initState() {
    super.initState();
    // 通知サービスの初期化
    SimpleNotificationService.initialize();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRunning) return;
      
      // 画面が破棄されていたらsetStateを呼ばない（エラー防止）
      if (!mounted) return; 

      setState(() {
        elapsedSeconds++;
        angle += pi / 30; // 1秒ごとに更新・60stepで1周

        // 時間超過時の通知ロジック
        if (widget.duration.inSeconds > 0 && 
            elapsedSeconds >= widget.duration.inSeconds && 
            !_hasNotified) {
          
          _triggerTimeOverNotification();
          _hasNotified = true; // 連続で通知されないようにフラグを立てる
        }
      });
    });
  }

  // ====== 修正ポイント：参考コードに合わせてメソッドを分離 ======
  Future<void> playSound() async {
    await player.play(AssetSource(audioSourceUrl));
  }

  Future<void> vibration() async {
    await HapticFeedback.lightImpact();
  }

  // 通知を実行するメソッド
  Future<void> _triggerTimeOverNotification() async {
    playSound();
    vibration();
    debugPrint("Time over notification triggered!"); // デバッグログ

    // 画面にローカル通知を出す
    await SimpleNotificationService.showNotification(
      id: 1, 
      title: '時間超過のお知らせ',
      body: '「${widget.selectedTitle}」の目標時間を超過しました！',
    );
  }
  // ============================================================

  void _toggleTimer() {
    setState(() {
      isRunning = !isRunning;
    });
  }

  void _finishMeasurement() {
    Navigator.of(context).pop(Duration(seconds: elapsedSeconds));
  }

  @override
  void dispose() {
    _timer.cancel();
    player.dispose(); // メモリリークを防ぐためにplayerも破棄
    super.dispose();
  }

  String formatDuration(int seconds) {
    final d = Duration(seconds: seconds.abs());
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final int showSeconds = !isOver ? remaining : (elapsedSeconds - widget.duration.inSeconds);
    final stoppedText = '経過時間: ' + formatDuration(elapsedSeconds);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.selectedTitle),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isRunning ? displayText : '計測停止中',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, color: displayColor),
            ),
            const SizedBox(height: 10),
            Text(
              isRunning ? formatDuration(showSeconds) : stoppedText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 50, color: Colors.blueGrey),
            ),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                    ),
                    ClockHand(
                      angle: angle,
                      length: 100,
                      thickness: 2,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.red[300] : Colors.green[300],
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: Text(isRunning ? 'ストップ' : '再開'),
            ),
            if (!isRunning)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton(
                  onPressed: _finishMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[200],
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('前の画面に戻る'),
                ),
              )
          ],
        ),
      ),
    );
  }
}