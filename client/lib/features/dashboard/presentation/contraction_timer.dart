import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class ContractionSession {
  final String id;
  final int duration;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final double frequency;

  ContractionSession({
    required this.id,
    required this.duration,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.frequency,
  });
}

class ContractionTrackerScreen extends StatefulWidget {
  const ContractionTrackerScreen({super.key});

  @override
  State<ContractionTrackerScreen> createState() =>
      _ContractionTrackerScreenState();
}

class _ContractionTrackerScreenState extends State<ContractionTrackerScreen>
    with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  List<ContractionSession> _sessions = [];
  Timer? _timer;
  var _duration = 0;
  double _frequency = 0.0;
  DateTime? _startTime;
  DateTime? _lastEndTime;
  var _isActive = false;
  var _sessionId = '';
  var _isButtonDisabled = false;

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
          .from('contraction_sessions')
          .select()
          .order('start_time', ascending: false);

      final sessions = (response as List).map((session) {
        return ContractionSession(
          id: session['session_id'],
          duration: session['duration'],
          createdAt: DateTime.parse(session['created_at']),
          startTime: DateTime.parse(session['start_time']),
          endTime: DateTime.parse(session['end_time']),
          frequency: (session['frequency'] as num).toDouble(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _lastEndTime = sessions.isNotEmpty ? sessions.first.endTime : null;
        });
      }
    } on PlatformException catch (e) {
      _showError('Network error: ${e.message}');
    } catch (e) {
      _showError('Failed to load sessions: ${e.toString()}');
    }
  }

  Future<void> _saveSession() async {
    try {
      final endTime = DateTime.now();
      
      // First save to Supabase
      await _supabase.from('contraction_sessions').insert({
        'session_id': _sessionId,
        'duration': _duration,
        'start_time': _startTime!.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'frequency': _frequency,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update local state after successful save
      if (mounted) {
        setState(() {
          _sessions.insert(0, ContractionSession(
            id: _sessionId,
            duration: _duration,
            createdAt: DateTime.now(),
            startTime: _startTime!,
            endTime: endTime,
            frequency: _frequency,
          ));
          _lastEndTime = endTime;
        });
      }

    } on PostgrestException catch (e) {
      _showError('Database error: ${e.message}');
      throw Exception('Database operation failed');
    } catch (e) {
      _showError('Failed to save session: ${e.toString()}');
      throw Exception('Save operation failed');
    }
  }

  void _startContraction() {
    if (_isActive) return;

    final now = DateTime.now();
    setState(() {
      _isActive = true;
      _startTime = now;
      _sessionId = 'session_${now.microsecondsSinceEpoch}';
      _duration = 0;
    });

    // Calculate frequency after UI update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastEndTime != null) {
        final difference = now.difference(_lastEndTime!);
        setState(() => _frequency = difference.inSeconds / 60);
      } else {
        setState(() => _frequency = 0.0);
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _duration++);
    });
  }

  void _stopContraction() async {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _isButtonDisabled = true;
    });

    try {
      await _saveSession();
      _resetCounters();
    } catch (e) {
      _showError('Failed to save session. Please check your connection.');
    } finally {
      Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isButtonDisabled = false);
      });
    }
  }

  void _resetCounters() {
    if (mounted) {
      setState(() {
        _duration = 0;
        _frequency = 0.0;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppPallete.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contraction Timer',
            style: TextStyle(color: AppPallete.whiteColor)),
        backgroundColor: AppPallete.primaryFgColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildChart(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildControls(),
              const SizedBox(height: 24),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPallete.greyColor.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          )
        ],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: _sessions.length.toDouble(),
          minY: 0,
          maxY: _sessions
                  .fold(
                      0,
                      (max, session) =>
                          session.duration > max ? session.duration : max)
                  .toDouble() +
              5,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt() + 1}',
                  style: TextStyle(color: AppPallete.textColor),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 30,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}s',
                  style: TextStyle(color: AppPallete.textColor),
                ),
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _sessions
                  .asMap()
                  .entries
                  .map((e) =>
                      FlSpot(e.key.toDouble(), e.value.duration.toDouble()))
                  .toList(),
              isCurved: true,
              color: AppPallete.gradient2,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppPallete.gradient2.withOpacity(0.3),
                    AppPallete.gradient1.withOpacity(0.1)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatBadge(Icons.timer, 'Duration', '$_duration s'),
        _StatBadge(Icons.repeat, 'Frequency',
            _frequency > 0 ? '${_frequency.toStringAsFixed(1)} min' : '-'),
        _StatBadge(Icons.history, 'Sessions', '${_sessions.length}'),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPallete.greyColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: Icon(
              _isActive ? Icons.stop : Icons.play_arrow,
              size: 28,
              color: AppPallete.whiteColor,
            ),
            label: Text(
              _isActive ? 'END CONTRACTION' : 'START CONTRACTION',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPallete.whiteColor,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonDisabled
                  ? AppPallete.greyColor
                  : (_isActive
                      ? AppPallete.gradient1
                      : AppPallete.primaryFgColor),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isButtonDisabled
                ? null
                : (_isActive ? _stopContraction : _startContraction),
          ),
          const SizedBox(height: 16),
          Text(
            _isActive
                ? 'Contraction in progress...'
                : 'Press start when contraction begins',
            style: TextStyle(
              color: _isActive ? AppPallete.gradient1 : AppPallete.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppPallete.whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPallete.greyColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
          )
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return Card(
            color: AppPallete.whiteColor,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(
                'Contraction ${index + 1}',
                style: TextStyle(color: AppPallete.primaryFgColor),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duration: ${session.duration} seconds',
                      style: TextStyle(color: AppPallete.greyColor)),
                  Text(
                      'Frequency: ${session.frequency.toStringAsFixed(1)} minutes',
                      style: TextStyle(color: AppPallete.greyColor)),
                  Text('Time: ${DateFormat('HH:mm').format(session.startTime)}',
                      style: TextStyle(color: AppPallete.greyColor)),
                ],
              ),
              trailing: Text(DateFormat('MMM dd').format(session.createdAt),
                  style: TextStyle(color: AppPallete.greyColor)),
            ),
          );
        },
      ),
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
        Icon(icon, size: 32, color: AppPallete.primaryFgColor),
        const SizedBox(height: 8),
        Text(title,
            style: TextStyle(
              fontSize: 14,
              color: AppPallete.textColor,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 16,
              color: AppPallete.primaryFgColor,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}