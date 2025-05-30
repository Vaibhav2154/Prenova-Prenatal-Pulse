import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'package:prenova/features/BabyStatus/models/pregnancy_stage_model.dart';
import 'package:prenova/features/BabyStatus/presentation/pregnancy_week_screen.dart';
import 'package:prenova/features/BabyStatus/services/pregnancy_stage_service.dart';

class PregnancyStagesScreen extends StatefulWidget {
  final bool showAsCard;

  const PregnancyStagesScreen({Key? key, this.showAsCard = false})
      : super(key: key);

  @override
  _PregnancyStagesScreenState createState() => _PregnancyStagesScreenState();
}

class _PregnancyStagesScreenState extends State<PregnancyStagesScreen>
    with TickerProviderStateMixin {
  List<PregnancyStageModel> stages = [];
  bool isLoading = true;
  int selectedTrimester = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadStages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStages() async {
    try {
      final loadedStages = await PregnancyStagesService.loadPregnancyStages();
      setState(() {
        stages = loadedStages;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading pregnancy stages: $e');
    }
  }

  List<PregnancyStageModel> get filteredStages {
    return stages.where((stage) {
      // First trimester: weeks 1-13
      // Second trimester: weeks 14-27
      // Third trimester: weeks 28-40
      switch (selectedTrimester) {
        case 1:
          return stage.week <= 13;
        case 2:
          return stage.week >= 14 && stage.week <= 27;
        case 3:
          return stage.week >= 28;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppPallete.gradient1,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading pregnancy journey...',
                      style: TextStyle(
                        color: AppPallete.textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (stages.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else ...[
            _buildTrimesterSelector(),
            _buildStagesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppPallete.gradient1,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Pregnancy Journey',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPallete.gradient1,
                AppPallete.gradient2,
                AppPallete.gradient3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/logo.png', // Add your pattern image
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 60,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Baby\'s Growth',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${stages.length} weeks of development',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrimesterSelector() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppPallete.gradient1.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [1, 2, 3].map((trimester) {
            bool isSelected = selectedTrimester == trimester;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTrimester = trimester;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [AppPallete.gradient1, AppPallete.gradient2],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppPallete.gradient1.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Trimester $trimester',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppPallete.textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStagesList() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final stage = filteredStages[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: TweenAnimationBuilder(
                duration: Duration(milliseconds: 600 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildStageCard(stage, index),
                    ),
                  );
                },
              ),
            );
          },
          childCount: filteredStages.length,
        ),
      ),
    );
  }

  Widget _buildStageCard(PregnancyStageModel stage, int index) {
    final colors = [
      AppPallete.gradient1,
      AppPallete.gradient2,
      AppPallete.gradient3,
      Colors.pink.shade400,
      Colors.teal.shade400,
    ];
    final cardColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PregnancyWeekDetailScreen(stage: stage),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Week number circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardColor, cardColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${stage.week}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'WEEK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.title,
                        style: TextStyle(
                          color: AppPallete.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cardColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Size: ${stage.babySize}',
                          style: TextStyle(
                            color: cardColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stage.description,
                        style: TextStyle(
                          color: AppPallete.textColor.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Arrow
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: cardColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPallete.gradient1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.baby_changing_station,
              size: 60,
              color: AppPallete.gradient1,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No pregnancy stages available',
            style: TextStyle(
              color: AppPallete.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check back later for updates',
            style: TextStyle(
              color: AppPallete.textColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}