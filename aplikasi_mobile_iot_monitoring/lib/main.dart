import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const IotApp());

class IotApp extends StatelessWidget {
  const IotApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'IoT Monitoring',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const DashboardPage(),
  );
}

class Reading {
  final String time;
  final double temp;
  const Reading(this.time, this.temp);
}

String _fmt(DateTime t, {bool seconds = false}) {
  String p(int n) => n.toString().padLeft(2, '0');
  return seconds ? '${p(t.hour)}:${p(t.minute)}:${p(t.second)}' : '${p(t.hour)}:${p(t.minute)}';
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ---- DATA DUMMY (nanti diganti data dari MQTT) ----
  bool connected = true;
  double temp = 30.5;
  double hum = 75;
  DateTime lastUpdate = DateTime.now();
  bool expanded = false;
  final String broker = 'broker.hivemq.com';
  final String topic = 'kampus/iot/kelas1/sensor';
  final List<Reading> history = const [
    Reading('10:00', 28),
    Reading('10:05', 29),
    Reading('10:10', 28.5),
    Reading('10:15', 30.5),
  ].toList();

  Timer? _timer;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    // Simulasi data baru tiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!connected) return;
      setState(() {
        temp = double.parse((27 + _rnd.nextDouble() * 5).toStringAsFixed(1));
        hum = (70 + _rnd.nextInt(15)).toDouble();
        lastUpdate = DateTime.now();
        history.add(Reading(_fmt(lastUpdate), temp));
        if (history.length > 6) history.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('IoT Monitoring', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: Icon(Icons.circle, size: 12, color: connected ? Colors.green : Colors.red),
              label: Text(connected ? 'Connected' : 'Disconnected'),
              onPressed: () => setState(() => connected = !connected),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Dashboard Monitoring Sensor', style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SensorCard(
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: '${temp.toStringAsFixed(1)}°C',
                  sensor: 'Sensor DHT11',
                  bg: const Color(0xFFE3F2FD),
                  fg: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SensorCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${hum.toStringAsFixed(0)}%',
                  sensor: 'Sensor DHT11',
                  bg: const Color(0xFFE8F5E9),
                  fg: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _mqttCard(),
          const SizedBox(height: 16),
          _historyCard(),
        ],
      ),
    );
  }

  Widget _mqttCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MQTT Connection', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _infoRow('Status', connected ? 'Connected' : 'Disconnected',
            color: connected ? Colors.green : Colors.red),
        _infoRow('Broker', broker),
        _infoRow('Topic', topic),
        _infoRow('Last Update', _fmt(lastUpdate, seconds: true)),
      ],
    ),
  );

  Widget _infoRow(String k, String v, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Flexible(
          child: Text(v,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    ),
  );

  Widget _historyCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monitoring History', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Temperature (°C)', style: TextStyle(fontSize: 12, color: Colors.black54)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(6)),
              child: const Text('Dummy Data', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Contoh data simulasi untuk desain dashboard.', style: TextStyle(fontSize: 13)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Collapse chart' : 'Expand chart', style: const TextStyle(fontSize: 11)),
          ),
        ),
        SizedBox(
          height: expanded ? 300 : 160,
          width: double.infinity,
          child: CustomPaint(painter: LineChartPainter(history.map((e) => e.temp).toList())),
        ),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: SizedBox()),
          Expanded(child: Text('Temperature', style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const Divider(),
        for (final r in history.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(child: Text(r.time, style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('${r.temp}°C')),
            ]),
          ),
      ],
    ),
  );
}

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sensor;
  final Color bg, fg;

  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.sensor,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: fg),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: fg, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(sensor, style: TextStyle(color: fg, fontSize: 11)),
      ],
    ),
  );
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final axis = Paint()..color = Colors.black26..strokeWidth = 1;
    final line = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = Colors.blue;

    const pad = 16.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    canvas.drawLine(Offset(pad, pad), Offset(pad, size.height - pad), axis);
    canvas.drawLine(Offset(pad, size.height - pad), Offset(size.width - pad, size.height - pad), axis);

    final minV = data.reduce(min) - 1, maxV = data.reduce(max) + 1;
    final pts = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(pad + w * i / (data.length - 1), pad + h * (1 - (data[i] - minV) / (maxV - minV))),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
    for (final p in pts) {
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) => old.data != data;
}
