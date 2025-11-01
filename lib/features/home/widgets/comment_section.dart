// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\comment_section.dart

// lib/features/home/widgets/comment_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/comment.dart';
import '../../../core/providers/comment_provider.dart';
import '../../../core/providers/user_data_provider.dart';

class CommentSection extends StatefulWidget {
  final String contentId;

  const CommentSection({super.key, required this.contentId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    final userData = context.read<UserDataProvider>().userData;
    final newComment = Comment(
      id: const Uuid().v4(),
      text: _commentController.text.trim(),
      userId: userData.name!,
      userName: userData.name!,
      userProfilePicture: userData.profilePicturePath,
      timestamp: DateTime.now(),
    );

    try {
      await context
          .read<CommentProvider>()
          .addComment(widget.contentId, newComment);
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        StreamProvider<List<Comment>>.value(
          value: context.read<CommentProvider>().getComments(widget.contentId),
          initialData: const [],
          child: Consumer<List<Comment>>(
            builder: (context, comments, child) {
              if (comments.isEmpty) {
                return const Text('No comments yet. Be the first to comment!');
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: comment.userProfilePicture != null
                          ? NetworkImage(comment.userProfilePicture!)
                          : null,
                      child: comment.userProfilePicture == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(comment.userName),
                    subtitle: Text(comment.text),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addComment,
            ),
          ],
        ),
      ],
    );
  }
}
