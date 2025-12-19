import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothDevice? device;

  BluetoothCharacteristic? tempChar;
  BluetoothCharacteristic? humChar;
  BluetoothCharacteristic? cmdChar;

  double temperature = 0;
  double humidity = 0;

  List<FlSpot> tempData = [];
  int time = 0;

  @override
  void initState() {
    super.initState();
    scan();
  }

  void scan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name == "ESP32_IOT_Device") {
          device = r.device;
          FlutterBluePlus.stopScan();
          await connect();
          break;
        }
      }
    });
  }

  Future<void> connect() async {
    await device!.connect();
    final services = await device!.discoverServices();

    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.uuid.toString() == tempCharUUID) tempChar = c;
        if (c.uuid.toString() == humCharUUID) humChar = c;
        if (c.uuid.toString() == cmdCharUUID) cmdChar = c;
      }
    }

    await tempChar!.setNotifyValue(true);
    await humChar!.setNotifyValue(true);

    tempChar!.value.listen((value) {
      setState(() {
        temperature = double.parse(utf8.decode(value));
        tempData.add(FlSpot(time.toDouble(), temperature));
        time++;
      });
    });

    humChar!.value.listen((value) {
      setState(() {
        humidity = double.parse(utf8.decode(value));
      });
    });
  }

  void sendCommand(String cmd) {
    cmdChar?.write(utf8.encode(cmd));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IoT Bluetooth Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            sensorCard("Температура", "$temperature °C", Icons.thermostat),
            sensorCard("Вологість", "$humidity %", Icons.water_drop),
            const SizedBox(height: 10),
            chart(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand("ON"),
                  child: const Text("УВІМКНУТИ"),
                ),
                ElevatedButton(
                  onPressed: () => sendCommand("OFF"),
                  child: const Text("ВИМКНУТИ"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget sensorCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget chart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: tempData,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: false),
            )
          ],
        ),
      ),
    );
  }
}
