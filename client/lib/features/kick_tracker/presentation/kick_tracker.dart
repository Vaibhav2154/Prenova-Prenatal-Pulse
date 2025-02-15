import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class KickSession {
  final String id;
  final int kickCount;
  final int duration;
  final DateTime createdAt;
  final List<FlSpot> data;

  KickSession({
    required this.id,
    required this.kickCount,
    required this.duration,
    required this.createdAt,
    required this.data,
  });
}

class KickTrackerScreen extends StatefulWidget {
  const KickTrackerScreen({super.key});

  @override
  State<KickTrackerScreen> createState() => _KickTrackerScreenState();
}

class _KickTrackerScreenState extends State<KickTrackerScreen>
    with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  List<KickSession> _sessions = [];
  final List<FlSpot> _currentData = [];
  Timer? _timer;
  var _elapsedSeconds = 0;
  var _kickCount = 0;
  var _isTracking = false;
  var _sessionId = '';
  var _isButtonDisabled = false; // New state variable for button cooldown

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSessions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final response = await _supabase
          .from('kick_sessions')
          .select()
          .order('created_at', ascending: false);

      final sessions = (response as List)
          .map((session) => KickSession(
                id: session['session_id'],
                kickCount: session['kick_count'],
                duration: session['elapsed_seconds'],
                createdAt: DateTime.parse(session['created_at']),
                data: _parseChartData(session['kick_data'] is String
                    ? List<Map<String, dynamic>>.from(jsonDecode(session['kick_data']))
                    : session['kick_data']),
              ))
          .toList();

      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      _showError('Failed to load sessions: ${e.toString()}');
    }
  }

  List<FlSpot> _parseChartData(List<dynamic> data) {
    return data
        .map<FlSpot>((point) => FlSpot(point['x'].toDouble(), point['y'].toDouble()))
        .toList();
  }

  Future<void> _saveSession() async {
    try {
      await _supabase.from('kick_sessions').upsert({
        'session_id': _sessionId,
        'kick_count': _kickCount,
        'elapsed_seconds': _elapsedSeconds,
        'kick_data': jsonEncode(_currentData.map((p) => {'x': p.x, 'y': p.y}).toList()),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _loadSessions();
    } catch (e) {
      _showError('Failed to save session: ${e.toString()}');
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _resetCounters();
      _sessionId = DateTime.now().toIso8601String();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _currentData.add(FlSpot(_elapsedSeconds.toDouble(), _kickCount.toDouble()));
      });
    });
  }

  void _stopTracking() async {
    _timer?.cancel();
    setState(() => _isTracking = false);
    await _saveSession();
  }

  void _recordKick() {
    if (_isTracking && !_isButtonDisabled) {
      setState(() {
        _kickCount++;
        _isButtonDisabled = true;
      });
      
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _isButtonDisabled = false);
        }
      });
    }
  }

  void _resetCounters() {
    _elapsedSeconds = 0;
    _kickCount = 0;
    _currentData.clear();
    _isButtonDisabled = false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby Kick Tracker'),
      ),
      body: Column(
        children: [
          _buildChart(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildControls(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSessionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: _elapsedSeconds.toDouble(),
          minY: 0,
          maxY: (_kickCount.toDouble() + 5).clamp(0.0, double.infinity),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: _bottomTitles),
            leftTitles: AxisTitles(sideTitles: _leftTitles),
          ),
          backgroundColor: AppPallete.textColor,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
         // backgroundColor: AppPallete.textColor,
          lineBarsData: [
            LineChartBarData(
              spots: _currentData.isEmpty ? [FlSpot(0, 0)] : _currentData,
              isCurved: true,
              color: Colors.pink,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.withOpacity(0.3),
                    Colors.pink.withOpacity(0.1)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: 60,
        getTitlesWidget: (value, meta) => Text('${value.toInt()}s',style: TextStyle(),),
      );

  SideTitles get _leftTitles => SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: 5,
        getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
      );

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatBadge(Icons.timer, 'Duration', '$_elapsedSeconds s'),
        _StatBadge(Icons.favorite, 'Kicks', '$_kickCount'),
        _StatBadge(Icons.show_chart, 'Sessions', '${_sessions.length}'),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
          label: Text(_isTracking ? 'STOP' : 'START'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isTracking ? Colors.red : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: _isTracking ? _stopTracking : _startTracking,
        ),
        const SizedBox(width: 20),
        FloatingActionButton(
          onPressed: _isButtonDisabled || !_isTracking ? null : _recordKick,
          backgroundColor: _isButtonDisabled 
              ? Colors.pink.withOpacity(0.5)
              : Colors.pink,
          child: const Icon(Icons.favorite_border, size: 28),
        ),
      ],
    );
  }

  Widget _buildSessionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text('Session ${index + 1}'),
            subtitle: Text(
              '${session.kickCount} kicks in ${session.duration} seconds',
            ),
            trailing: Text(
              '${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}',
            ),
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatBadge(this.icon, this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.pink),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}