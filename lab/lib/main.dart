import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

const String serviceUUID = "12345678-1234-1234-1234-1234567890ab";
const String characteristicUUID = "abcd1234-5678-1234-5678-abcdef123456";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BluetoothPage(),
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
  BluetoothCharacteristic? characteristic;
  String receivedData = "Очікування даних...";

  @override
  void initState() {
    super.initState();
    scanDevices();
  }

  void scanDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == "ESP32_IOT_Device") {
          device = r.device;
          FlutterBluePlus.stopScan();
          await connectToDevice();
          break;
        }
      }
    });
  }

  Future<void> connectToDevice() async {
    if (device == null) return;

    await device!.connect();
    List<BluetoothService> services = await device!.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var c in service.characteristics) {
          if (c.uuid.toString() == characteristicUUID) {
            characteristic = c;
            await characteristic!.setNotifyValue(true);

            characteristic!.value.listen((value) {
              setState(() {
                receivedData = utf8.decode(value);
              });
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IoT Bluetooth Monitor"),
      ),
      body: Center(
        child: Text(
          receivedData,
          style: const TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
