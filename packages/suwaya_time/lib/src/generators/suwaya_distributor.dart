import '../models/astro_models.dart';
import '../calculators/prayer_calculator.dart';

class SuwayaDistributor {
  
  static List<int> distribute48Suwayas(List<int> durationsInSeconds) {
    if (durationsInSeconds.isEmpty || durationsInSeconds.fold(0, (a, b) => a + b) == 0) {
      return [7, 7, 6, 7, 7, 7, 7]; // حالة طوارئ آمنة
    }

    // 🌟 1. استخراج متوسط الكتل المتطابقة (Block Grouping)
    double d1 = (durationsInSeconds[0] + durationsInSeconds[1]) / 2.0; // الفجر والضحى
    double d3 = durationsInSeconds[2].toDouble(); // الظهر
    double d4 = durationsInSeconds[3].toDouble(); // العصر
    double d5 = (durationsInSeconds[4] + durationsInSeconds[5] + durationsInSeconds[6]) / 3.0; // أثلاث الليل

    double totalSecs = (2 * d1) + d3 + d4 + (3 * d5);

    // 🌟 2. حساب الحصة الرياضية الدقيقة بالكسور لكل كتلة
    double e1 = 48.0 * (d1 / totalSecs);
    double e3 = 48.0 * (d3 / totalSecs);
    double e4 = 48.0 * (d4 / totalSecs);
    double e5 = 48.0 * (d5 / totalSecs);

    int b1 = e1.floor();
    int b3 = e3.floor();
    int b4 = e4.floor();
    int b5 = e5.floor();

    double bestError = double.infinity;
    int bestS1 = b1, bestS3 = b3, bestS4 = b4, bestS5 = b5;

    // 🌟 3. خوارزمية البحث الشامل لاختيار أفضل توليفة رياضية تحترم التكتل وقيد الـ 48
    for (int s1 = b1 - 1; s1 <= b1 + 2; s1++) {
      if (s1 < 1) continue;
      for (int s3 = b3 - 1; s3 <= b3 + 2; s3++) {
        if (s3 < 1) continue;
        for (int s4 = b4 - 1; s4 <= b4 + 2; s4++) {
          if (s4 < 1) continue;
          for (int s5 = b5 - 1; s5 <= b5 + 2; s5++) {
            if (s5 < 1) continue;

            // شرط الجبر: يجب أن يكون المجموع 48 سويعة بالضبط
            if ((2 * s1) + s3 + s4 + (3 * s5) == 48) {
              
              // حساب معامل الخطأ المطلق (نبحث عن التوليفة الأقرب للزمن الواقعي)
              double error = 2 * (s1 - e1).abs() +
                             (s3 - e3).abs() +
                             (s4 - e4).abs() +
                             3 * (s5 - e5).abs();

              if (error < bestError) {
                bestError = error;
                bestS1 = s1; bestS3 = s3; bestS4 = s4; bestS5 = s5;
              } else if (error == bestError) {
                // كاسر التعادل: نفضل إعطاء السويعة الزائدة لليل ثم للفجر
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

    // 🌟 إعادة تفكيك الكتل وتوزيعها بالتساوي المطلق
    return [bestS1, bestS1, bestS3, bestS4, bestS5, bestS5, bestS5];
  }

  static List<int> calculateAnnualDistribution(double lat, double lng, CalculationMethodType methodType, MadhabType madhabType, HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}) {
    List<int> totalDurations = List.filled(7, 0);
    final int year = DateTime.now().year;
    final List<int> sampleDays = [1, 6, 11, 16, 21, 26]; 
    
    for (int month = 1; month <= 12; month++) {
      for (int day in sampleDays) {
        final date = DateTime(year, month, day);
        final ibadat = PrayerCalculator.getIbadatTimings(lat, lng, date, methodType, madhabType, highLatRuleType, customFajr, customIsha, cityOffset, manualOffsets: manualOffsets);
        
        final midFajr = ibadat.fajr.add(Duration(microseconds: ibadat.dhuhr.difference(ibadat.fajr).inMicroseconds ~/ 2));
        final nightMicro = ibadat.nextFajr.difference(ibadat.maghrib).inMicroseconds;
        final nightThird = Duration(microseconds: nightMicro ~/ 3);
        final firstThirdEnd = ibadat.maghrib.add(nightThird);
        final secondThirdEnd = firstThirdEnd.add(nightThird);

        totalDurations[0] += midFajr.difference(ibadat.fajr).inSeconds;
        totalDurations[1] += ibadat.dhuhr.difference(midFajr).inSeconds;
        totalDurations[2] += ibadat.asr.difference(ibadat.dhuhr).inSeconds;
        totalDurations[3] += ibadat.maghrib.difference(ibadat.asr).inSeconds;
        totalDurations[4] += firstThirdEnd.difference(ibadat.maghrib).inSeconds;
        totalDurations[5] += secondThirdEnd.difference(firstThirdEnd).inSeconds;
        totalDurations[6] += ibadat.nextFajr.difference(secondThirdEnd).inSeconds;
      }
    }
    
    // نمرر المجموع المباشر للخوارزمية وهي ستتكفل بحساب المتوسطات وتوزيع الكتل
    return distribute48Suwayas(totalDurations);
  }
}