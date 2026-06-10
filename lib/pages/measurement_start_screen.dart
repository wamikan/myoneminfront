import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'schedule_creation_screen.dart';
import '../models/schedule.dart'; // Scheduleクラスをインポート
import 'measurement_running_screen.dart';
import 'show_history.dart';

//import '../services/schedule_service.dart';

class MeasurementStartScreen extends StatefulWidget {
  const MeasurementStartScreen({super.key});

  @override
  State<MeasurementStartScreen> createState() => _MeasurementStartScreenState();
}

class _MeasurementStartScreenState extends State<MeasurementStartScreen> {
  List<Schedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('schedules') ?? [];
    final schedules = stored.map((encoded) {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return _scheduleFromMap(decoded);
    }).toList();
    setState(() {
      _schedules = schedules;
    });
  }

  Future<void> _saveSchedules(List<Schedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = schedules
        .map((schedule) => jsonEncode(_scheduleToMap(schedule)))
        .toList();
    await prefs.setStringList('schedules', encoded);
  }

  // スケジュール作成画面に遷移し、新しいスケジュールを受け取るメソッド
  void _navigateAndAddSchedule(BuildContext context) async {
    // Map形式でデータを受け取るように変更
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleCreationScreen()),
    );

    // データが返ってきた場合、Scheduleオブジェクトを生成してリストに追加
    if (result != null) {
      final newSchedule = Schedule(
        title: result['title'] as String,
        duration: result['duration'] as Duration,
      );
      setState(() {
        _schedules = [..._schedules, newSchedule];
      });
      await _saveSchedules(_schedules);
    }
  }

  Future<void> _deleteSchedule(int index) async {
    setState(() {
      _schedules = List.of(_schedules)..removeAt(index);
    });
    await _saveSchedules(_schedules);
  }

  Future<void> _openMeasurementPage(int index) async {
    final schedule = _schedules[index];
    final result = await Navigator.push<Duration>(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementPage(
          selectedTitle: schedule.title,
          duration: schedule.duration,
        ),
      ),
    );
    if (result != null) {
      final his = List<MeasurementHistory>.from(schedule.histories)
        ..add(MeasurementHistory(
          target: schedule.duration,
          actual: result,
          timestamp: DateTime.now(),
        ));
      setState(() {
        _schedules[index] = schedule.copyWith(histories: his);
      });
      await _saveSchedules(_schedules);
    }
  }

  Map<String, dynamic> _scheduleToMap(Schedule schedule) => schedule.toJson();
  Schedule _scheduleFromMap(Map<String, dynamic> map) => Schedule.fromJson(map);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours時間');
    }
    if (minutes > 0) {
      parts.add('$minutes分');
    }
    if (parts.isEmpty) {
      parts.add('0分');
    }
    return parts.join(' ');
  }

  String _actualDurationText(Schedule s) {
    if (s.histories.isEmpty) return '';
    final d = s.histories.last.actual;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final l = <String>[];
    if (h > 0) l.add('${h}時間');
    if (m > 0) l.add('${m}分');
    if (l.isEmpty) l.add('0分');
    return '（実績: ${l.join(' ')}）';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('測定開始')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'スケジュール一覧',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_schedules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'スケジュールがありません。\n下のボタンから作成してください。',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // スケジュールリストの表示部分を修正
            Expanded(
              child: ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  final durationText = _formatDuration(schedule.duration);
                  return Card(
                    child: ListTile(
                      title: Text(schedule.title),
                      subtitle: Text('所要時間: $durationText ${_actualDurationText(schedule)}'),
                      onTap: () => _openMeasurementPage(index),

                      trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShowHistoryPage(
                                  title: schedule.title,
                                  targetDuration: schedule.duration,
                                  // 【重要】ScheduleのhistoriesをShowHistoryPage用のResultItemに変換する
                                  histories: schedule.histories.map((h) {
                                    // hはおそらくMeasurementHistory型（target, actualを持っていると仮定）
                                    return ResultItem(h.target, h.actual);
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      // trailing: Row(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     IconButton(
                      //       icon: const Icon(Icons.history),
                      //       onPressed: () {
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //             builder: (_) => ShowHistoryPage(
                      //               title: schedule.title,
                      //               histories: schedule.histories,
                      //               targetDuration: schedule.duration,
                      //             ),
                      //           ),
                      //         );
                      //       },
                      //     ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSchedule(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndAddSchedule(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'スケジュールを作成',
      ),
    );
  }
}
