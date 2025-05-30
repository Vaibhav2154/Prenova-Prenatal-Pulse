import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import '../models/pregnancy_stage_model.dart';

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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBabySizeCard(),
                  const SizedBox(height: 20),
                  _buildDescriptionCard(),
                  const SizedBox(height: 20),
                  _buildKeyDevelopmentsCard(),
                  const SizedBox(height: 20),
                  _buildMotherSymptomsCard(),
                  const SizedBox(height: 20),
                  _buildTipsCard(),
                  const SizedBox(height: 40),
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
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: AppPallete.gradient1,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          // backdrop: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            // backdrop: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          ),
          child: Text(
            'Week ${stage.week}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
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
            fit: StackFit.expand,
            children: [
              // Background pattern
              Opacity(
                opacity: 0.1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/logo.png'),
                      fit: BoxFit.cover,
                      opacity: 0.1,
                    ),
                  ),
                ),
              ),
              // Baby image container
              Container(
                margin: const EdgeInsets.only(top: 80, left: 40, right: 40, bottom: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
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
              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.baby_changing_station,
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Baby Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabySizeCard() {
    return _buildModernInfoCard(
      icon: Icons.straighten,
      title: 'Baby Size',
      content: [stage.babySize],
      color: AppPallete.gradient1,
      subtitle: 'Current development size',
    );
  }

  Widget _buildDescriptionCard() {
    return _buildModernInfoCard(
      icon: Icons.info_outline,
      title: stage.title,
      content: [stage.description],
      color: AppPallete.gradient2,
      subtitle: 'Week overview',
    );
  }

  Widget _buildKeyDevelopmentsCard() {
    return _buildModernInfoCard(
      icon: Icons.trending_up,
      title: 'Key Developments',
      content: stage.keyDevelopments,
      color: AppPallete.gradient3,
      subtitle: 'Important milestones',
    );
  }

  Widget _buildMotherSymptomsCard() {
    return _buildModernInfoCard(
      icon: Icons.favorite,
      title: 'Mother\'s Experience',
      content: stage.motherSymptoms,
      color: Colors.pink.shade400,
      subtitle: 'What you might feel',
    );
  }

  Widget _buildTipsCard() {
    return _buildModernInfoCard(
      icon: Icons.lightbulb_outline,
      title: 'Tips for Parents',
      content: stage.tipsForParents,
      color: Colors.teal.shade400,
      subtitle: 'Helpful guidance',
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required List<String> content,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppPallete.textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1'),
                        style: TextStyle(
                          fontSize: 15,
                          color: AppPallete.textColor.withOpacity(0.8),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}