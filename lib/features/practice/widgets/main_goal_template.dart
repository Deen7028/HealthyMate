/// Data used to configure a predefined main goal in the selection sheet.
class MainGoalTemplate {
  final String title;
  final String icon;
  final String defaultUnit;
  final String linkedWorkout;
  final double defaultTarget;
  const MainGoalTemplate({
    required this.title,
    required this.icon,
    required this.defaultUnit,
    required this.linkedWorkout,
    required this.defaultTarget,
  });
}
