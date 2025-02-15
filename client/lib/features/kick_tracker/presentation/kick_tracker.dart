import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:async';
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTracking();
      _saveSession(); // Automatically save session on pause
    }
  }

  Future<void> _loadSessions() async {
    try {
      final response = await _supabase
          .from('kick_sessions') // Corrected table name
          .select()
          .order('created_at', ascending: false);

      final sessions = (response as List)
          .map((session) => KickSession(
                id: session['session_id'],
                kickCount: session['kick_count'],
                duration: session['elapsed_seconds'],
                createdAt: DateTime.parse(session['created_at']),
                data: _parseChartData(session['kick_data']),
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
        'kick_data': _currentData.map((p) => {'x': p.x, 'y': p.y}).toList(),
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

  void _pauseTracking() {
    if (_isTracking) {
      _timer?.cancel();
      setState(() => _isTracking = false);
    }
  }

  void _recordKick() {
    if (_isTracking) {
      setState(() => _kickCount++);
    }
  }

  void _resetCounters() {
    _elapsedSeconds = 0;
    _kickCount = 0;
    _currentData.clear();  // Make sure to clear the chart data when resetting
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showSessionHistory,
            tooltip: 'Session History',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildChart(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildControls(),
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
          maxY: (_kickCount.toDouble() + 5).clamp(0.0, double.infinity), // Dynamic maxY
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: _bottomTitles),
            leftTitles: AxisTitles(sideTitles: _leftTitles),
          ),
          backgroundColor: AppPallete.textColor,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          backgroundColor: AppPallete.textColor,
          lineBarsData: [
            LineChartBarData(
              spots: _currentData.isEmpty ? [FlSpot(0, 0)] : _currentData, // Ensure chart is not empty
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
          onPressed: _recordKick,
          backgroundColor: Colors.pink,
          child: const Icon(Icons.favorite_border, size: 28),
        ),
      ],
    );
  }

  void _showSessionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _sessions.length,
            itemBuilder: (_, index) => ListTile(
              title: Text('Session ${index + 1}'),
              subtitle: Text(
                '${_sessions[index].kickCount} kicks - '
                '${_sessions[index].duration}s',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteSession(_sessions[index].id),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSession(String id) async {
    try {
      await _supabase.from('kick_sessions').delete().eq('session_id', id);
      await _loadSessions();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to delete session: ${e.toString()}');
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBadge(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.pink),
        ),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
