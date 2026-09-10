import '../models/astro_models.dart';

class SuwayaDistributor {
  // 🌟 المعيار العالمي الموحد (الذي يستخدمه التطبيق الفعلي الآن)
  static const List<int> universalDistribution = [7, 7, 7, 6, 7, 7, 7];

  // 🌟 أعدنا هذه الدالة لكي لا تنكسر اختباراتك، ولتبقى كأداة رياضية متاحة في الحزمة
  static List<int> distribute48Suwayas(List<int> durationsInSeconds) {
    if (durationsInSeconds.isEmpty || durationsInSeconds.fold(0, (a, b) => a + b) == 0) {
      return universalDistribution;
    }

    double d1 = (durationsInSeconds[0] + durationsInSeconds[1]) / 2.0; 
    double d3 = durationsInSeconds[2].toDouble(); 
    double d4 = durationsInSeconds[3].toDouble(); 
    double d5 = (durationsInSeconds[4] + durationsInSeconds[5] + durationsInSeconds[6]) / 3.0; 

    double totalSecs = (2 * d1) + d3 + d4 + (3 * d5);
    double e1 = 48.0 * (d1 / totalSecs);
    double e3 = 48.0 * (d3 / totalSecs);
    double e4 = 48.0 * (d4 / totalSecs);
    double e5 = 48.0 * (d5 / totalSecs);

    int b1 = e1.floor(), b3 = e3.floor(), b4 = e4.floor(), b5 = e5.floor();
    double bestError = double.infinity;
    int bestS1 = b1, bestS3 = b3, bestS4 = b4, bestS5 = b5;

    for (int s1 = b1 - 1; s1 <= b1 + 2; s1++) {
      if (s1 < 1) continue;
      for (int s3 = b3 - 1; s3 <= b3 + 2; s3++) {
        if (s3 < 1) continue;
        for (int s4 = b4 - 1; s4 <= b4 + 2; s4++) {
          if (s4 < 1) continue;
          for (int s5 = b5 - 1; s5 <= b5 + 2; s5++) {
            if (s5 < 1) continue;

            if ((2 * s1) + s3 + s4 + (3 * s5) == 48) {
              double error = 2 * (s1 - e1).abs() + (s3 - e3).abs() + (s4 - e4).abs() + 3 * (s5 - e5).abs();
              if (error < bestError) {
                bestError = error;
                bestS1 = s1; bestS3 = s3; bestS4 = s4; bestS5 = s5;
              } else if (error == bestError) {
                if (s5 > bestS5) {
                  bestS1 = s1; bestS3 = s3; bestS4 = s4; bestS5 = s5;
                } else if (s5 == bestS5 && s1 > bestS1) {
                  bestS1 = s1; bestS3 = s3; bestS4 = s4; bestS5 = s5;
                }
              }
            }
          }
        }
      }
    }
    return [bestS1, bestS1, bestS3, bestS4, bestS5, bestS5, bestS5];
  }

  // 🌟 التطبيق سيعتمد على هذه الدالة التي ترجع الثابت عالمياً بدون استهلاك المعالج
  static List<int> calculateAnnualDistribution(
    double lat, double lng, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) {
    return universalDistribution;
  }
}