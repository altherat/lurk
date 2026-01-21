import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';

class PostDetails {
  
  final Post post;
  final List<CommentItem> comments;

  PostDetails({
    required this.post,
    required this.comments,
  });

}