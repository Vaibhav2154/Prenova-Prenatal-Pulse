import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _loadSessions();
    _fadeController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
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
      
      await _supabase.from('contraction_sessions').insert({
        'session_id': _sessionId,
        'duration': _duration,
        'start_time': _startTime!.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'frequency': _frequency,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

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

    _pulseController.repeat(reverse: true);

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
    _pulseController.stop();
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
          content: Row(
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppPallete.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Contraction Timer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: AppPallete.gradient1.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              _buildMainTimerCard(),
              SizedBox(height: 24),
              _buildStatsRow(),
              SizedBox(height: 24),
              _buildChart(),
              SizedBox(height: 24),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTimerCard() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isActive ? AppPallete.gradient1 : Colors.white,
            _isActive ? AppPallete.gradient2 : Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isActive 
                ? AppPallete.gradient1.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isActive ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isActive ? Colors.white.withOpacity(0.2) : AppPallete.gradient1.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isActive ? Colors.white : AppPallete.gradient1,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${(_duration ~/ 60).toString().padLeft(2, '0')}:${(_duration % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isActive ? Colors.white : AppPallete.textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              icon: Icon(
                _isActive ? LucideIcons.square : LucideIcons.play,
                size: 24,
                color: Colors.white,
              ),
              label: Text(
                _isActive ? 'END CONTRACTION' : 'START CONTRACTION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonDisabled
                    ? AppPallete.greyColor
                    : (_isActive ? Colors.red[600] : AppPallete.gradient1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: _isActive 
                    ? Colors.red.withOpacity(0.3)
                    : AppPallete.gradient1.withOpacity(0.3),
              ),
              onPressed: _isButtonDisabled
                  ? null
                  : (_isActive ? _stopContraction : _startContraction),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _isActive
                ? 'Contraction in progress... Stay calm and breathe'
                : 'Press start when contraction begins',
            style: TextStyle(
              color: _isActive ? Colors.white.withOpacity(0.9) : AppPallete.textColor.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(LucideIcons.timer, 'Duration', '$_duration s', AppPallete.gradient1)),
        SizedBox(width: 16),
        Expanded(child: _StatCard(LucideIcons.repeat, 'Frequency', 
            _frequency > 0 ? '${_frequency.toStringAsFixed(1)} min' : '-', AppPallete.gradient2)),
        SizedBox(width: 16),
        Expanded(child: _StatCard(LucideIcons.activity, 'Sessions', '${_sessions.length}', AppPallete.gradient3)),
      ],
    );
  }

  Widget _buildChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.trendingUp, color: AppPallete.gradient1, size: 20),
              SizedBox(width: 8),
              Text(
                'Contraction Pattern',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: _sessions.length.toDouble(),
                minY: 0,
                maxY: _sessions.isEmpty ? 100 : _sessions
                        .fold(0, (max, session) => session.duration > max ? session.duration : max)
                        .toDouble() + 20,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt() + 1}',
                        style: TextStyle(color: AppPallete.textColor.withOpacity(0.7), fontSize: 12),
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
                        style: TextStyle(color: AppPallete.textColor.withOpacity(0.7), fontSize: 12),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sessions.isEmpty 
                        ? [FlSpot(0, 0)]
                        : _sessions
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.duration.toDouble()))
                            .toList(),
                    isCurved: true,
                    color: AppPallete.gradient1,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppPallete.gradient1,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppPallete.gradient1.withOpacity(0.3),
                          AppPallete.gradient1.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(LucideIcons.clock, color: AppPallete.gradient1, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            child: _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.clock, size: 48, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No contractions recorded yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 20),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 8, left: 20, right: 20),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPallete.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppPallete.gradient1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.activity,
                                color: AppPallete.gradient1,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contraction ${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppPallete.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Duration: ${session.duration}s • Frequency: ${session.frequency.toStringAsFixed(1)} min',
                                    style: TextStyle(
                                      color: AppPallete.textColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(session.startTime),
                              style: TextStyle(
                                color: AppPallete.textColor.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard(this.icon, this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppPallete.textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: AppPallete.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}