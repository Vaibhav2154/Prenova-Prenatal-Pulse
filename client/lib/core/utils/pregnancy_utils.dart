class PregnancyUtils {
  /// Calculate current pregnancy week based on due date
  static int getCurrentPregnancyWeek(String dueDateString) {
    try {
      final dueDate = DateTime.parse(dueDateString);
      final now = DateTime.now();
      
      // Calculate conception date (due date - 280 days)
      final conceptionDate = dueDate.subtract(Duration(days: 280));
      
      // Calculate weeks since conception
      final daysSinceConception = now.difference(conceptionDate).inDays;
      final currentWeek = (daysSinceConception / 7).floor();
      
      // Ensure week is between 1 and 40
      return currentWeek.clamp(1, 40);
    } catch (e) {
      print('Error calculating pregnancy week: $e');
      return 1; // Default to week 1 if calculation fails
    }
  }
  
  /// Alternative calculation based on trimester
  static int getWeekFromTrimester(int trimester) {
    switch (trimester) {
      case 1:
        return 12; // Mid-first trimester
      case 2:
        return 24; // Mid-second trimester
      case 3:
        return 32; // Mid-third trimester
      default:
        return 12;
    }
  }
}