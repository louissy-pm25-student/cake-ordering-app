/// Immutable management record. IDs remain stable when names change.
class AdminRecord {
  final String id;
  final Map<String, dynamic> values;
  AdminRecord(this.id, Map<String, dynamic> values)
    : values = Map.unmodifiable(values);
  String text(String key, [String fallback = '']) =>
      '${values[key] ?? fallback}';
  double number(String key) => double.tryParse(text(key)) ?? 0;
  bool flag(String key) => values[key] == true || values[key] == 'true';
  AdminRecord patch(Map<String, dynamic> changes) =>
      AdminRecord(id, {...values, ...changes});
  Map<String, dynamic> toJson() => {'id': id, ...values};
  factory AdminRecord.fromJson(Map<String, dynamic> json) =>
      AdminRecord(json['id'] as String, Map.of(json)..remove('id'));
}
