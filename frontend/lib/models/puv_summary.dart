import 'puv_model.dart';

class PuvSummary {
  final int registeredCount;
  final int vehicleTypeCount;
  final int totalCapacity;

  const PuvSummary({
    required this.registeredCount,
    required this.vehicleTypeCount,
    required this.totalCapacity,
  });

  factory PuvSummary.fromRecords(List<PuvModel> records) {
    return PuvSummary(
      registeredCount: records.length,
      vehicleTypeCount: records
          .map((record) => record.puvType.trim().toLowerCase())
          .toSet()
          .length,
      totalCapacity: records.fold<int>(
        0,
        (total, record) => total + record.capacity,
      ),
    );
  }

  static List<PuvModel> search(List<PuvModel> records, String query) {
    final normalized = query.trim().toLowerCase();

    return records.where((record) {
      return record.puvType.toLowerCase().contains(normalized) ||
          record.puvId.toString().contains(normalized);
    }).toList();
  }

  static String registrationDate(DateTime? date) {
    if (date == null) return 'Unavailable';

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
