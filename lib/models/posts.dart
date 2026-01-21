import 'package:lurk/models/post.dart';

class Posts {

  final List<Post> posts;
  final String? pageToken;

  const Posts({
    required this.posts,
    this.pageToken,
  });

}