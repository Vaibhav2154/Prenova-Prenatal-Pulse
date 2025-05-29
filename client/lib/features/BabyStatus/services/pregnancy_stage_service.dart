import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/pregnancy_stage_model.dart';

class PregnancyStagesService {
  static Future<List<PregnancyStageModel>> loadPregnancyStages() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'lib/core/constants/pregnancystages.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> stagesJson = jsonData['pregnancy_stages_weekly'] ?? [];
      
      return stagesJson
          .map((json) => PregnancyStageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading pregnancy stages: $e');
      return [];
    }
  }

  static List<int> getAvailableMonths(List<PregnancyStageModel> stages) {
    return stages.map((stage) => stage.month).toSet().toList()..sort();
  }

  static List<PregnancyStageModel> getWeeksForMonth(
    List<PregnancyStageModel> stages,
    int month,
  ) {
    return stages.where((stage) => stage.month == month).toList();
  }
}