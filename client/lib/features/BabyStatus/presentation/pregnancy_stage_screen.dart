import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import '../models/pregnancy_stage_model.dart';
import '../services/pregnancy_stage_service.dart';

class PregnancyWeekDetailScreen extends StatelessWidget {
  final PregnancyStageModel stage;

  const PregnancyWeekDetailScreen({
    Key? key,
    required this.stage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBabySizeCard(),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(),
                  const SizedBox(height: 16),
                  _buildKeyDevelopmentsCard(),
                  const SizedBox(height: 16),
                  _buildMotherSymptomsCard(),
                  const SizedBox(height: 16),
                  _buildTipsCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppPallete.gradient1,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Week ${stage.week}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPallete.gradient1, AppPallete.gradient2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: stage.imagePath.isNotEmpty
                      ? Image.asset(
                          stage.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: const Center(
        child: Icon(
          Icons.baby_changing_station,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBabySizeCard() {
    return _buildInfoCard(
      icon: Icons.straighten,
      title: 'Baby Size',
      content: [stage.babySize],
      color: AppPallete.gradient1,
    );
  }

  Widget _buildDescriptionCard() {
    return _buildInfoCard(
      icon: Icons.info_outline,
      title: stage.title,
      content: [stage.description],
      color: AppPallete.gradient2,
    );
  }

  Widget _buildKeyDevelopmentsCard() {
    return _buildInfoCard(
      icon: Icons.trending_up,
      title: 'Key Developments',
      content: stage.keyDevelopments,
      color: AppPallete.gradient3,
    );
  }

  Widget _buildMotherSymptomsCard() {
    return _buildInfoCard(
      icon: Icons.favorite,
      title: 'Mother\'s Symptoms',
      content: stage.motherSymptoms,
      color: Colors.deepOrangeAccent,
    );
  }

  Widget _buildTipsCard() {
    return _buildInfoCard(
      icon: Icons.lightbulb_outline,
      title: 'Tips for Parents',
      content: stage.tipsForParents,
      color: Colors.teal,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1'),
                          style: TextStyle(
                            fontSize: 15,
                            color: AppPallete.textColor.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// If you need a screen to show all pregnancy stages
class PregnancyStagesScreen extends StatefulWidget {
  final bool showAsCard;

  const PregnancyStagesScreen({Key? key, this.showAsCard = false})
      : super(key: key);

  @override
  _PregnancyStagesScreenState createState() => _PregnancyStagesScreenState();
}

class _PregnancyStagesScreenState extends State<PregnancyStagesScreen> {
  List<PregnancyStageModel> stages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  Future<void> _loadStages() async {
    try {
      // Import the service at the top of the file
      final loadedStages = await PregnancyStagesService.loadPregnancyStages();
      setState(() {
        stages = loadedStages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading pregnancy stages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Pregnancy Journey',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppPallete.gradient1,
        elevation: 0,
        flexibleSpace: Container(),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppPallete.gradient1,
              ),
            )
          : stages.isEmpty
              ? Center(
                  child: Text(
                    'No pregnancy stages available',
                    style: TextStyle(
                      color: AppPallete.textColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    return Card(
                      color: AppPallete.accentFgColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppPallete.gradient1,
                          child: Text(
                            '${stage.week}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          stage.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          stage.babySize,
                          style: TextStyle(
                            color: AppPallete.whiteColor.withOpacity(0.7),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: AppPallete.gradient1,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PregnancyWeekDetailScreen(stage: stage),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
