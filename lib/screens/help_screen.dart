import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/fv_list_card.dart';
import '../widgets/fv_screen.dart';

/// Static informational content from the designs: FAQ, About and Contact.
///
/// These are read-only reference pages. They are driven from data below rather
/// than hand-built widgets, so a new question or team member is a one-line
/// change.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'FAQ'),
              Tab(text: 'About'),
              Tab(text: 'Contact'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_FaqTab(), _AboutTab(), _ContactTab()],
        ),
      ),
    );
  }
}

/// One question and its answer. Answers are honest about what is simulated,
/// which the designs do deliberately on the shop screens.
class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

const List<_Faq> _faqs = [
  _Faq(
    'Is Fandom Verse free?',
    'Yes. Discovery, saving and community tools are free to explore. '
        'Merchandise listings are fictional demo data.',
  ),
  _Faq(
    'How does offline saving work?',
    'The feed you last loaded is stored on your device in a local database, so '
        'it opens without a connection. Images and video come from a disk cache.',
  ),
  _Faq(
    'Are shop orders real?',
    'No. Checkout is a simulation - nothing is charged and nothing is delivered. '
        'No payment provider is connected.',
  ),
  _Faq(
    'How do event tickets work?',
    'Registration is marked locally and "Get ticket" links out. There is no '
        'ticketing backend, so no ticket is actually issued.',
  ),
  _Faq(
    'What can the AI Fan Helper answer?',
    'It can help with watch orders, lore basics and finding what you have '
        'saved. It is a research assistant, not a search engine.',
  ),
  _Faq(
    'How do badges work?',
    'They unlock from what you actually do - posts, likes received, saves, '
        'communities joined. You can pin an earned one to your profile.',
  ),
];

class _FaqTab extends StatefulWidget {
  const _FaqTab();

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  // One open at a time, matching the accordion in the designs.
  int? _open;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (var i = 0; i < _faqs.length; i++)
          _FaqTile(
            faq: _faqs[i],
            expanded: _open == i,
            onTap: () => setState(() => _open = _open == i ? null : i),
          ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq, required this.expanded, required this.onTap});

  final _Faq faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // A plus that becomes a minus, rather than a chevron: the
                    // designs use this control for expand/collapse.
                    Icon(
                      expanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Text(
                    faq.answer,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamMember {
  const _TeamMember(this.name, this.role);

  final String name;
  final String role;
}

const List<_TeamMember> _team = [
  _TeamMember('Mina', 'Community'),
  _TeamMember('Theo', 'Product'),
  _TeamMember('Ada', 'Engineering'),
];

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: FvScreenHeader(
            title: 'Built by fans, for fans',
            subtitle: 'A small team connecting every kind of fandom.',
          ),
        ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.groups_outlined, size: 56, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        const Text(
          'We make discovery joyful, community safer and deep fandom knowledge '
          'easier to carry everywhere.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Our team',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final member in _team)
          FvListCard(
            title: member.name,
            subtitle: member.role,
            icon: Icons.person_outline,
          ),
        const SizedBox(height: 8),
        const Text(
          'Fandom Verse is a demo project. Listings, events and orders are '
          'sample data.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _ContactTab extends StatefulWidget {
  const _ContactTab();

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _topic = 'Events and meetups';
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // There is no mail backend, so this records the intent and says so rather
    // than pretending a message was delivered.
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return FvEmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'Thanks, that is noted',
        message: 'No mail backend is connected yet, so nothing was actually sent. '
            'This is a demo form.',
        action: OutlinedButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text('Write another'),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Enter name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Tell us who you are' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Email', hintText: 'Enter email'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter an email';
              if (!value.contains('@')) return 'That does not look like an email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _topic,
            dropdownColor: AppColors.elevated,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Topic'),
            items: const [
              DropdownMenuItem(value: 'Events and meetups', child: Text('Events and meetups')),
              DropdownMenuItem(value: 'A bug I found', child: Text('A bug I found')),
              DropdownMenuItem(value: 'Something else', child: Text('Something else')),
            ],
            onChanged: (v) => setState(() => _topic = v ?? _topic),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _messageController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Enter message',
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Add a message' : null,
          ),
          const SizedBox(height: 20),
          FvPrimaryButton(label: 'Send inquiry', onPressed: _submit),
          const SizedBox(height: 20),
          FvListCard(
            title: 'hello@fandomverse.app',
            subtitle: 'Mon-Fri, 9 AM-5 PM',
            icon: Icons.mail_outline,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
