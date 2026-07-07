import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _title = TextEditingController();
  final _brief = TextEditingController();
  bool _loading = false;

  void _submit() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KonektaColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Campaign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Influencer card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE3E9F2))),
                child: Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFB6E2C8), borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Selected Influencer', style: TextStyle(fontSize: 12, color: KonektaColors.textMuted)),
                          SizedBox(height: 2),
                          Text('Sarah Creative', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: KonektaColors.textMuted, size: 20), onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Campaign Title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _title,
                decoration: const InputDecoration(hintText: 'e.g. Summer Coffee Collection', prefixIcon: Icon(Icons.title_rounded, color: KonektaColors.textMuted)),
              ),
              const SizedBox(height: 16),
              const Text('Campaign Brief', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
              const SizedBox(height: 6),
              TextField(
                controller: _brief,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Describe the campaign goals, deliverables, and expectations...',
                  prefixIcon: Icon(Icons.description_rounded, color: KonektaColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Budget (IDR)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(hintText: 'e.g. Rp 2,400,000', prefixIcon: Icon(Icons.attach_money_rounded, color: KonektaColors.textMuted)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KonektaColors.textDark)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: KonektaColors.softBlue, borderRadius: BorderRadius.circular(28)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: KonektaColors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    const Text('Select a date', style: TextStyle(color: KonektaColors.textMuted, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: KonektaColors.textMuted, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: _loading ? 'Creating...' : 'Create Campaign',
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _brief.dispose();
    super.dispose();
  }
}
