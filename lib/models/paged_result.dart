class PagedResult<T> {

  final List<T> items;
  final String? pageToken;

  PagedResult({
    required this.items,
    this.pageToken,
  });
  
}