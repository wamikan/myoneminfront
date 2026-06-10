import 'package:flutter/material.dart';
import 'measurement_running_screen.dart';

class ResultPage extends StatefulWidget {
    final int limit;
    final int remaining;

    const ResultPage({
    Key? key,
    required this.limit,
    required this.remaining,
  }) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late int limit;
  late int measured;
  late int remaining;

  @override
  void initState() {
    super.initState();
    limit = widget.limit;
    remaining = widget.remaining;
    measured = limit - remaining;
  }

  String formatDuration(int seconds) {
   final d = Duration(seconds: seconds.abs());
   final h = d.inHours.toString().padLeft(2, '0');
   final m = (d.inMinutes % 60).toString().padLeft(2, '0');
   final s = (d.inSeconds % 60).toString().padLeft(2, '0');
   return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false, // 戻るボタンを非表示にする
      ),
      body: Padding(
        //16ピクセルの余白
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            //後で作り直します
            Text(formatDuration(limit)),
            Text(formatDuration(measured)),
            Text(formatDuration(remaining)),
            ElevatedButton(
              onPressed: () {

              },
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[300],
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
              ),
              child: const Text('スタートに戻る'),
            ),
          ]
        )
      ),
    );
  }
}
