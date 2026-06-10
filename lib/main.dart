import 'dart:async'; // 追加：タイマー用
import 'dart:convert'; // 追加：データのエンコード/デコード用
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 追加：ローカル保存用

import 'package:onemin_front/models/schedule.dart'; // 追加：Scheduleモデルのインポート

// 既存のインポート
import 'package:onemin_front/pages/show_history.dart';
import 'package:onemin_front/pages/schedule_creation_screen.dart';
import 'package:onemin_front/pages/measurement_start_screen.dart';
import 'package:onemin_front/pages/notification_timer_page.dart';
import 'package:onemin_front/pages/measurement_running_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // ==========================================
  // スタート画面用の状態変数
  // ==========================================
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now().toUtc().add(const Duration(hours: 9)); // 東京時間に設定
  List<Schedule> _schedules = [];
  
  // 変更：Scheduleオブジェクトの代わりに「タイトル(文字列)」で選択状態を管理します
  String? _selectedTitle; 

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now().toUtc().add(const Duration(hours: 9));
      });
    });
    _loadSchedules();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('schedules') ?? [];
    final schedules = stored.map((encoded) {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return Schedule.fromJson(decoded);
    }).toList();

    setState(() {
      _schedules = schedules;
      // 選択されていた予定が削除されるなどして無くなった場合はリセット
      if (_selectedTitle != null && _selectedTitle != "__NO_SCHEDULE__") {
        final exists = _schedules.any((s) => s.title == _selectedTitle);
        if (!exists) _selectedTitle = null;
      }
    });
  }

  Future<void> _saveSchedules(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = schedules
        .map((schedule) => jsonEncode(schedule.toJson()))
        .toList();
    await prefs.setStringList('schedules', encoded);
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeString = "${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}";

    // 現在選択されている具体的なスケジュールオブジェクトを取得（目標時間表示用）
    Schedule? currentSchedule;
    if (_selectedTitle != null && _selectedTitle != "__NO_SCHEDULE__" && _selectedTitle != "__CREATE_NEW__") {
      try {
        currentSchedule = _schedules.firstWhere((s) => s.title == _selectedTitle);
      } catch (e) {
        currentSchedule = null;
      }
    }

    // プルダウンの選択肢を作成
    List<DropdownMenuItem<String>> dropdownItems = [
      const DropdownMenuItem(
        value: "__CREATE_NEW__", 
        child: Text("＋ 新規予定作成", style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold))
      ),
      const DropdownMenuItem(
        value: "__NO_SCHEDULE__", 
        child: Text("予定を選択せず開始", style: TextStyle(fontSize: 18, color: Colors.green))
      ),
    ];
    // 保存されているスケジュールを追加
    dropdownItems.addAll(_schedules.map((Schedule schedule) {
      return DropdownMenuItem<String>(
        value: schedule.title,
        child: Text(schedule.title, style: const TextStyle(fontSize: 18)),
      );
    }));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 30),
              
              // 1. 現在時刻の表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 4),
                ),
                child: Column(
                  children: [
                    const Text('現在時刻', style: TextStyle(fontSize: 24)),
                    Text(
                      timeString,
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              const Text('これからの予定', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              const Text('予定を選択⇓', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 10),

              // 2. 予定のプルダウン選択
              DropdownButton<String>(
                hint: const Text('予定を選択してください', style: TextStyle(fontSize: 18)),
                // __CREATE_NEW__の時は表示をリセット（遷移だけするため）
                value: _selectedTitle == "__CREATE_NEW__" ? null : _selectedTitle,
                items: dropdownItems,
                onChanged: (String? newValue) async {
                  if (newValue == "__CREATE_NEW__") {
                    // 「新規予定作成」が選ばれたら作成画面へ
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(builder: (context) => const ScheduleCreationScreen()),
                    );
                    // 作成して戻ってきたら、その予定をリストに追加して選択状態にする
                    if (result != null) {
                      final newSchedule = Schedule(
                        title: result['title'] as String,
                        duration: result['duration'] as Duration,
                      );
                      setState(() {
                        _schedules = [..._schedules, newSchedule];
                        _selectedTitle = newSchedule.title; // 作った予定を選択
                      });
                      await _saveSchedules(_schedules);
                    }
                  } else {
                    // それ以外の場合は普通に選択状態を更新
                    setState(() {
                      _selectedTitle = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 30),

              // 3. 目標時間の表示
              const Text('目標時間', style: TextStyle(fontSize: 24)),
              Text(
                currentSchedule != null
                    ? "${currentSchedule.duration.inHours.toString().padLeft(2, '0')}:${(currentSchedule.duration.inMinutes % 60).toString().padLeft(2, '0')}"
                    : (_selectedTitle == "__NO_SCHEDULE__" ? "00:00" : "--:--"), // 予定なしの場合は00:00
                style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // 4. スタートボタン
              ElevatedButton(
                onPressed: _selectedTitle == null 
                    ? null // 未選択の場合はボタン無効
                    : () async {
                        String targetTitle = "予定なし";
                        Duration targetDuration = Duration.zero;

                        // 選択された予定がある場合は、そのタイトルと時間を渡す
                        if (_selectedTitle != "__NO_SCHEDULE__" && currentSchedule != null) {
                          targetTitle = currentSchedule!.title;
                          targetDuration = currentSchedule!.duration;
                        }

                        // 計測画面へ遷移
                        final result = await Navigator.push<Duration>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MeasurementPage(
                              selectedTitle: targetTitle,
                              duration: targetDuration,
                            ),
                          ),
                        );

                        // 計測が完了し、結果が返ってきたら履歴に保存する
                        if (result != null) {
                          int index = _schedules.indexWhere((s) => s.title == targetTitle);
                          
                          if (index != -1) {
                            // 既存の予定に履歴を追加
                            final schedule = _schedules[index];
                            final his = List<MeasurementHistory>.from(schedule.histories)
                              ..add(MeasurementHistory(
                                target: schedule.duration,
                                actual: result,
                                timestamp: DateTime.now(),
                              ));
                            
                            setState(() {
                              _schedules[index] = schedule.copyWith(histories: his);
                            });
                          } else {
                            // 「予定なし」で計測した場合は、新しく「予定なし」というスケジュール枠を作って保存
                            final newSchedule = Schedule(
                              title: targetTitle,
                              duration: targetDuration,
                              histories: [
                                MeasurementHistory(
                                  target: targetDuration,
                                  actual: result,
                                  timestamp: DateTime.now(),
                                )
                              ]
                            );
                            setState(() {
                              _schedules.add(newSchedule);
                            });
                          }
                          // ローカルへ保存
                          await _saveSchedules(_schedules);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text('スタート', style: TextStyle(fontSize: 28, color: Colors.black)),
              ),
              const SizedBox(height: 10),

              // ==========================================
              // 【追加】履歴を表示ボタン
              // ==========================================
              TextButton(
                onPressed: () {
                  // measurement_start_screen（一覧画面）へ遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeasurementStartScreen(),
                    ),
                  ).then((_) => _loadSchedules()); // 戻ってきたら最新状態に更新
                },
                child: const Text(
                  '履歴を表示', 
                  style: TextStyle(fontSize: 18, color: Colors.deepOrange, decoration: TextDecoration.underline)
                ),
              ),

              const SizedBox(height: 50),
              const Divider(thickness: 2),
              const Text('--- 以下、既存のテスト用ボタン群 ---', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              
              // ==========================================
              // 以下、既存の要素 (一切削除していません)
              // ==========================================
              const Text('You have pushed the button this many times:'),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShowHistoryPage(
                          title: "show history page",
                          targetDuration: Duration(minutes: 10),
                          histories: [],
                        )
                    ),
                  );
                },
                child: const Text('Go to show_history'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationTimerPage(),
                    ),
                  );
                },
                child: const Text('Go to Start'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeasurementStartScreen(),
                    ),
                  ).then((_) => _loadSchedules());
                },
                child: const Text('Go to measurement_start_screen'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleCreationScreen(),
                    ),
                  ).then((_) => _loadSchedules());
                },
                child: const Text('Go to schedule_creation_screen'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeasurementPage(
                        selectedTitle: "テスト用予定名",
                        duration: Duration(minutes: 90), 
                      ),
                    ), 
                  );
                },
                child: const Text('Go to measurement_running_screen'),
              ),
              const SizedBox(height: 50), // スクロールの一番下の余白
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}