import 'package:flutter/material.dart';

import '../data/labels.dart';
import '../state/clinic_store.dart';
import '../widgets/ui.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final content = TextEditingController();
  final comment = TextEditingController();
  String category = 'educational';
  String? openPostId;

  @override
  void dispose() {
    content.dispose();
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'المجتمع الطبي', subtitle: 'منشورات توعوية من الأطباء المعتمدين', icon: Icons.forum_outlined),
        if (store.isDoctor && !store.doctorLocked)
          SectionCard(
            title: 'منشور جديد',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: [for (final e in postCategoriesAr.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                  onChanged: (v) => setState(() => category = v ?? category),
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                const SizedBox(height: 8),
                TextField(controller: content, maxLines: 3, decoration: const InputDecoration(labelText: 'المحتوى')),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () {
                      store.createPost(content.text, category);
                      content.clear();
                      toast(context, 'تم نشر المنشور');
                    },
                    child: const Text('نشر'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (final post in store.publishedPosts)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AvatarCircle(name: post.doctorName),
                    title: Text('د. ${post.doctorName}'),
                    subtitle: Text('${postCategoryAr(post.category)} · ${fromNow(post.createdDate)}'),
                    onTap: () => store.openDoctor(post.doctorId),
                  ),
                  Text(post.content),
                  const SizedBox(height: 8),
                  Row(children: [
                    TextButton.icon(
                      onPressed: () => store.toggleLike(post),
                      icon: Icon(store.likedPostIds.contains(post.id) ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      label: Text('${post.likesCount}'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => openPostId = openPostId == post.id ? null : post.id),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text('${post.commentsCount}'),
                    ),
                  ]),
                  if (openPostId == post.id) ...[
                    for (final c in store.commentsFor(post.id))
                      ListTile(dense: true, title: Text(c.authorName), subtitle: Text(c.content)),
                    Row(children: [
                      Expanded(child: TextField(controller: comment, decoration: const InputDecoration(hintText: 'أضف تعليقاً', isDense: true))),
                      IconButton(
                        onPressed: () {
                          store.addComment(post, comment.text);
                          comment.clear();
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
