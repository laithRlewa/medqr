import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

const _templates = [
  (
    'general',
    'متابعة عامة',
    [
      {'id': 'q1', 'type': 'text', 'question': 'كيف تشعر بعد الزيارة؟'},
      {'id': 'q2', 'type': 'choice', 'question': 'هل تحسنت الأعراض؟', 'options': ['تحسنت كثيراً', 'تحسنت قليلاً', 'بدون تغيير', 'ساءت']},
    ]
  ),
  (
    'medication',
    'متابعة الأدوية',
    [
      {'id': 'q1', 'type': 'choice', 'question': 'هل تلتزم بتناول الدواء؟', 'options': ['نعم', 'بشكل جزئي', 'لا']},
      {'id': 'q2', 'type': 'text', 'question': 'هل واجهت أي آثار جانبية؟'},
    ]
  ),
  (
    'pain',
    'متابعة الألم',
    [
      {'id': 'q1', 'type': 'rating', 'question': 'قيّم مستوى الألم (1-10)'},
      {'id': 'q2', 'type': 'choice', 'question': 'هل تحسن الألم منذ الزيارة؟', 'options': ['نعم', 'لا', 'جزئياً']},
    ]
  ),
];

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(ClinicStore store, String patientId, String doctorId) async {
    final body = text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    text.clear();
    await store.sendMessage(patientId: patientId, doctorId: doctorId, content: body);
    if (!mounted) return;
    setState(() => _sending = false);
    if (store.lastMessage != null) toast(context, store.lastMessage!);
    _scrollToEnd();
  }

  Future<void> _startChat(ClinicStore store) async {
    if (store.isDoctor) {
      final list = store.chatablePatients;
      if (list.isEmpty) {
        toast(context, 'لا يوجد مرضى متاحون للمحادثة بعد. افتح سجلاً عبر QR أولاً.');
        return;
      }
      final picked = await showModalBottomSheet<Patient>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => _PickSheet(
          title: 'اختر مريضاً للمحادثة',
          children: [
            for (final p in list)
              ListTile(
                leading: PhotoAvatar(name: p.fullName, size: 40, photo: p.profilePhoto),
                title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(p.patientId),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      );
      if (picked != null) store.openMessages(patientId: picked.id, doctorId: store.currentDoctor?.id);
      return;
    }

    var list = store.chatableDoctors;
    if (list.isEmpty) list = store.featuredDoctors.take(12).toList();
    if (list.isEmpty) {
      toast(context, 'لا يوجد أطباء متاحون. ابحث عن طبيب أولاً.');
      return;
    }
    final picked = await showModalBottomSheet<Doctor>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _PickSheet(
        title: 'اختر طبيباً للمحادثة',
        children: [
          for (final d in list)
            ListTile(
              leading: PhotoAvatar(name: d.fullName, size: 40, photo: d.profilePhoto),
              title: Text('د. ${d.fullName}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${d.specialty} · ${d.clinicName}'),
              onTap: () => Navigator.pop(ctx, d),
            ),
        ],
      ),
    );
    if (picked != null) store.openMessages(patientId: store.currentPatient?.id, doctorId: picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    String? patientId = store.selectedPatientId;
    String? doctorId = store.selectedDoctorId;
    if (store.isPatient) {
      patientId = store.currentPatient?.id;
      doctorId ??= store.selectedDoctorId;
    }
    if (store.isDoctor) {
      doctorId = store.currentDoctor?.id;
      patientId ??= store.selectedPatientId;
    }

    if (patientId != null && doctorId != null) {
      return Scaffold(
        backgroundColor: ClinicColors.bg,
        body: SafeArea(bottom: false, child: _thread(store, patientId, doctorId)),
      );
    }

    final summaries = store.conversationSummaries;
    return Scaffold(
      backgroundColor: ClinicColors.bg,
      body: ListView(
        padding: clinicPadding(context),
        children: [
          PageHeader(
            title: 'المحادثات',
            subtitle: store.isDoctor ? 'تواصل مع مرضاك' : 'تواصل مع أطبائك',
            icon: Icons.chat_bubble_outline,
            actions: [
              FilledButton.icon(
                onPressed: () => _startChat(store),
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: const Text('محادثة جديدة'),
              ),
            ],
          ),
          SoftCard(
            color: ClinicColors.tint,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const ClinicIllustration(ClinicArt.telemedicine, height: 64),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.isDoctor
                        ? 'يمكنك مراسلة المرضى الذين فتحت سجلاتهم أو زرتهم.'
                        : 'راسل طبيبك للاستفسار أو المتابعة بعد الزيارة.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (summaries.isEmpty)
            EmptyHint(
              store.isDoctor ? 'لا توجد محادثات بعد — ابدأ محادثة مع مريض' : 'لا توجد محادثات بعد — ابدأ محادثة مع طبيب',
              art: ClinicArt.telemedicine,
            )
          else
            for (final item in summaries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftCard(
                  onTap: () {
                    final parts = item.$1.split('__');
                    store.openMessages(patientId: parts.elementAtOrNull(0), doctorId: parts.elementAtOrNull(1));
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Badge(
                      isLabelVisible: item.$4 > 0,
                      label: Text('${item.$4}'),
                      child: CircleAvatar(
                        backgroundColor: ClinicColors.primary.withValues(alpha: 0.12),
                        child: Icon(Icons.chat_bubble_outline, color: ClinicColors.primary),
                      ),
                    ),
                    title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_left, color: ClinicColors.muted),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _thread(ClinicStore store, String patientId, String doctorId) {
    final items = store.messagesFor(patientId: patientId, doctorId: doctorId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.markConversationRead(store.conversationId(patientId, doctorId));
      _scrollToEnd();
    });
    final title = store.isDoctor
        ? (store.patientById(patientId)?.fullName ?? 'مريض')
        : 'د. ${store.doctorById(doctorId)?.fullName ?? ''}';
    final subtitle = store.isDoctor
        ? (store.patientById(patientId)?.patientId ?? 'محادثة خاصة')
        : (store.doctorById(doctorId)?.specialty ?? 'محادثة خاصة');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'كل المحادثات',
                  onPressed: () {
                    store.selectedPatientId = null;
                    store.selectedDoctorId = null;
                    store.goTo(ClinicPage.messages);
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
                PhotoAvatar(
                  name: title,
                  size: 40,
                  photo: store.isDoctor
                      ? store.patientById(patientId)?.profilePhoto
                      : store.doctorById(doctorId)?.profilePhoto,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(subtitle, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (store.isDoctor)
                  IconButton(
                    tooltip: 'استبيان متابعة',
                    onPressed: () => _followUp(store, patientId, doctorId),
                    icon: const Icon(Icons.assignment_outlined),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              if (items.isEmpty)
                const EmptyHint('ابدأ المحادثة — الرسائل تظهر للطرفين فوراً بعد الإرسال', art: ClinicArt.telemedicine, artHeight: 100)
              else
                for (final m in items) _bubble(store, m),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          elevation: 6,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 8, isMobileLayout(context) ? 78 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(store, patientId, doctorId),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _send(store, patientId, doctorId),
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(ClinicStore store, ChatMessage m) {
    final mine = m.senderUserId == store.currentUser?.id;
    if (m.messageType == 'followup' && m.questionnaire != null) {
      return _questionnaireCard(store, m);
    }
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: mine ? ClinicColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 4 : 16),
            bottomRight: Radius.circular(mine ? 16 : 4),
          ),
          border: mine ? null : Border.all(color: ClinicColors.border),
          boxShadow: softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(m.senderName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClinicColors.muted)),
            Text(m.content, style: TextStyle(color: mine ? Colors.white : ClinicColors.ink, height: 1.35)),
            const SizedBox(height: 4),
            Text(fromNow(m.createdDate), style: TextStyle(color: mine ? Colors.white70 : ClinicColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _questionnaireCard(ClinicStore store, ChatMessage m) {
    final q = m.questionnaire!;
    final questions = (q['questions'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final answers = Map<String, dynamic>.from(q['answers'] as Map? ?? {});
    final answered = q['answered'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q['title']?.toString() ?? 'استبيان متابعة', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final item in questions) ...[
            Text(item['question']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (answered)
              Text('الإجابة: ${answers[item['id']] ?? '—'}', style: const TextStyle(color: ClinicColors.muted))
            else if (store.isPatient)
              Material(
                color: Colors.transparent,
                child: _answerField(item, answers, () => setState(() {})),
              ),
            const SizedBox(height: 8),
          ],
          if (store.isPatient && !answered)
            FilledButton(
              onPressed: () async {
                await store.sendMessage(
                  patientId: m.patientId,
                  doctorId: m.doctorId,
                  content: 'تم إرسال إجابات الاستبيان',
                  messageType: 'followup',
                  questionnaire: {...q, 'answers': answers, 'answered': true},
                );
                _scrollToEnd();
              },
              child: const Text('إرسال الإجابات'),
            ),
        ],
      ),
      ),
    );
  }

  Widget _answerField(Map<String, dynamic> item, Map<String, dynamic> answers, VoidCallback refresh) {
    final id = item['id']?.toString() ?? '';
    final type = item['type']?.toString() ?? 'text';
    if (type == 'choice') {
      final options = (item['options'] as List? ?? []).map((e) => e.toString()).toList();
      return Wrap(
        spacing: 6,
        children: [
          for (final opt in options)
            ChoiceChip(label: Text(opt), selected: answers[id] == opt, onSelected: (_) { answers[id] = opt; refresh(); }),
        ],
      );
    }
    return TextFormField(
      initialValue: answers[id]?.toString() ?? '',
      onChanged: (v) => answers[id] = v,
      decoration: const InputDecoration(hintText: 'إجابتك'),
    );
  }

  Future<void> _followUp(ClinicStore store, String patientId, String doctorId) async {
    var key = 'general';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('إرسال استبيان متابعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in _templates)
                RadioListTile<String>(
                  value: t.$1,
                  groupValue: key,
                  title: Text(t.$2),
                  onChanged: (v) => setLocal(() => key = v ?? key),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final tpl = _templates.firstWhere((e) => e.$1 == key);
                await store.sendMessage(
                  patientId: patientId,
                  doctorId: doctorId,
                  content: 'استبيان متابعة: ${tpl.$2}',
                  messageType: 'followup',
                  questionnaire: {'title': tpl.$2, 'questions': tpl.$3, 'answered': false},
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _scrollToEnd();
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickSheet extends StatelessWidget {
  const _PickSheet({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          ...children,
        ],
      ),
    );
  }
}
