class Category {
  final int id;
  final String name;
  final String? defaultDepartment;
  final bool active;

  Category({
    required this.id,
    required this.name,
    this.defaultDepartment,
    required this.active,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'] ?? '',
    defaultDepartment: json['defaultDepartment'],
    active: json['active'] ?? true,
  );
}