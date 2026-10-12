class PageResponse<T> {
  final int totalPages;
  final int totalElements;
  final int size;
  final List<T> content;
  final int number;
  final bool first;
  final bool last;
  final bool empty;

  PageResponse({
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.content,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return PageResponse(
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      size: json['size'] ?? 0,
      content: (json['content'] as List).map((e) => fromJsonT(e)).toList(),
      number: json['number'] ?? 0,
      first: json['first'] ?? false,
      last: json['last'] ?? false,
      empty: json['empty'] ?? true,
    );
  }
}