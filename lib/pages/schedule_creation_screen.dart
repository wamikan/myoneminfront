import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScheduleCreationScreen extends StatefulWidget {
  const ScheduleCreationScreen({super.key});

  @override
  State<ScheduleCreationScreen> createState() => _ScheduleCreationScreenState();
}

class _ScheduleCreationScreenState extends State<ScheduleCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');

  @override
  void dispose() {
    _titleController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  // 保存ボタンが押されたときの処理
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final hours = int.tryParse(_hoursController.text) ?? 0;
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final totalMinutes = hours * 60 + minutes;
      if (totalMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('1分以上の時間を入力してください')),
        );
        return;
      }
      Navigator.pop(context, {
        'title': _titleController.text,
        'duration': Duration(minutes: totalMinutes),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('スケジュール作成')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // スケジュール名入力フォーム
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'スケジュール名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'スケジュール名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                '所要時間（タイマー）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '時間',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '分',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '※ 例: 1時間30分なら「時間=1」「分=30」',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: const Text('保存')),
            ],
          ),
        ),
      ),
    );
  }
}
