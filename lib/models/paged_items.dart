class PagedItems<T> {
  
  final List<T> items;
  final String? pageToken;

  PagedItems({
    required this.items,
    this.pageToken,
  });

}