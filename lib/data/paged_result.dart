/// Generic container for paginated backend responses matching backend PageResponse<T>
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PagedResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) fromJsonT,
  ) {
    final rawList = (json['content'] ?? json['items'] ?? []) as List<dynamic>;
    final items = rawList.map(fromJsonT).toList();
    final page = (json['pageNumber'] ?? json['page'] ?? json['number'] ?? 0) as int;
    final size = (json['pageSize'] ?? json['size'] ?? 10) as int;
    final totalElements = ((json['totalElements'] ?? json['total'] ?? items.length) as num).toInt();
    final totalPages = ((json['totalPages'] ?? (size > 0 ? (totalElements / size).ceil() : 1)) as num).toInt();
    final last = (json['last'] as bool?) ?? (page + 1 >= totalPages);

    return PagedResult<T>(
      items: items,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      last: last,
    );
  }

  factory PagedResult.empty({int page = 0, int size = 10}) {
    return PagedResult<T>(
      items: const [],
      page: page,
      size: size,
      totalElements: 0,
      totalPages: 0,
      last: true,
    );
  }
}
