import 'package:flutter/material.dart';

import '../state/admin_store.dart';
import '../widgets/ui.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final q = search.trim().toLowerCase();
    final filtered = store.posts.where((p) {
      if (q.isEmpty) return true;
      return p.content.toLowerCase().contains(q) || p.doctorName.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader(title: 'إدارة المنشورات', subtitle: 'عرض وحذف أي منشور يخالف السياسة'),
        SearchField(hint: 'بحث بالمحتوى، الطبيب، الفئة...', onChanged: (v) => setState(() => search = v)),
        const SizedBox(height: 16),
        if (filtered.isEmpty) const EmptyHint('لا توجد منشورات'),
        ...filtered.map((post) => Card(
              child: ListTile(
                leading: AvatarCircle(name: post.doctorName),
                title: Text('د. ${post.doctorName}'),
                subtitle: Text('${postCategoryAr(post.category)} · ${fromNow(post.createdDate, store.now)}\n${post.content}\n${post.likesCount} إعجاب · ${post.commentsCount} تعليق'),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    if (post.status != 'published') StatusChip(label: post.status, color: Colors.orange),
                    IconButton(
                      tooltip: 'حذف المنشور',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد الحذف'),
                            content: Text('هل أنت متأكد من حذف منشور "${post.doctorName}"؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          store.archivePost(post);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور')));
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
