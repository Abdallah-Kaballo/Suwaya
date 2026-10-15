import '../models/astro_models.dart';

class SuwayaDistributor {
  /// توزيع السويعات לפי معيار الجمهور (ظل المثل) - المجموع 24
  static const List<int> _jumhurDistribution = [1, 4, 6, 1, 6, 3, 3];
  
  /// توزيع السويعات לפי المعيار الحنفي (ظل المثلين) - المجموع 24
  static const List<int> _hanafiDistribution = [1, 4, 6, 1, 6, 4, 2];

  /// جلب التوزيع المناسب بناءً على المذهب
  static List<int> getDistributionForMadhab(MadhabType madhab) {
    return madhab == MadhabType.hanafi ? _hanafiDistribution : _jumhurDistribution;
  }
}