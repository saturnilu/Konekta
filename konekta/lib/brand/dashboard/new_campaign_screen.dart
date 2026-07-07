import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/app_scope.dart';
import '../../core/api_client.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../data/models/campaign.dart';
import 'brand_active_room_screen.dart';

class NewCampaignScreen extends StatefulWidget {
  const NewCampaignScreen({super.key});

  @override
  State<NewCampaignScreen> createState() => _NewCampaignScreenState();
}

class _NewCampaignScreenState extends State<NewCampaignScreen> {
  bool isPublic = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _briefController = TextEditingController();
  final TextEditingController _targetViewsController = TextEditingController();
  final TextEditingController _targetLikesController = TextEditingController();
  final List<Map<String, dynamic>> _targetMetrics = [];
  final List<Map<String, dynamic>> _requirementMetrics = [];

  static const List<Map<String, dynamic>> _targetMetricOptions = [
    {'icon': Icons.thumb_up_alt_outlined, 'label': 'Likes'},
    {'icon': Icons.mode_comment_outlined, 'label': 'Comments'},
    {'icon': Icons.share_outlined, 'label': 'Share'},
    {'icon': Icons.visibility_outlined, 'label': 'Views'},
  ];

  static const List<Map<String, dynamic>> _requirementMetricOptions = [
    {'icon': Icons.people_outline, 'label': 'Followers'},
    {'icon': Icons.workspace_premium_outlined, 'label': 'Total Completed Campaign'},
  ];

  void _addTargetMetric() {
    int selected = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Add Target Metric'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a metric and set a target value.'),
                  const SizedBox(height: 12),
                  ..._targetMetricOptions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final opt = entry.value;
                    final isSelected = selected == i;
                    return InkWell(
                      onTap: () => setLocalState(() => selected = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(opt['icon'] as IconData, size: 20, color: isSelected ? KonektaColors.primary : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? KonektaColors.primary : Colors.black,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 20,
                              color: isSelected ? KonektaColors.primary : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KonektaColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  final picked = _targetMetricOptions[selected];
                  Navigator.pop(ctx);
                  setState(() {
                    _targetMetrics.add({
                      'icon': picked['icon'],
                      'label': picked['label'],
                      'value': '',
                    });
                  });
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addRequirementMetric() {
    int selected = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Add Requirement Metric'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a requirement and set a value.'),
                  const SizedBox(height: 12),
                  ..._requirementMetricOptions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final opt = entry.value;
                    final isSelected = selected == i;
                    return InkWell(
                      onTap: () => setLocalState(() => selected = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(opt['icon'] as IconData, size: 20, color: isSelected ? KonektaColors.primary : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? KonektaColors.primary : Colors.black,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 20,
                              color: isSelected ? KonektaColors.primary : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KonektaColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  final picked = _requirementMetricOptions[selected];
                  Navigator.pop(ctx);
                  setState(() {
                    _requirementMetrics.add({
                      'icon': picked['icon'],
                      'label': picked['label'],
                      'value': '',
                    });
                  });
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeTargetMetric(int index) {
    setState(() => _targetMetrics.removeAt(index));
  }

  void _removeRequirementMetric(int index) {
    setState(() => _requirementMetrics.removeAt(index));
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final formatted = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      setState(() => _deadlineController.text = formatted);
    }
  }

  bool _saving = false;

  void _submit() async {
    final name = _nameController.text.trim();
    final brief = _briefController.text.trim();
    final rewardText = _rewardController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final budget = double.tryParse(rewardText) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign name is required')));
      return;
    }
    if (budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reward / budget is required')));
      return;
    }

    final targetViews = int.tryParse(_targetViewsController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final targetLikes = int.tryParse(_targetLikesController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (targetViews <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target views is required')));
      return;
    }
    if (targetLikes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target likes is required')));
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    setState(() => _saving = true);
    try {
      final scope = AppScope.of(context);
      final repo = CampaignRepository(scope.api);
      final campaign = await repo.create({
        'title': name,
        if (brief.isNotEmpty) 'brief': brief,
        'budget': budget,
        'reward_per_creator': budget,
        'max_creators': capacity,
        'target_views': targetViews,
        'target_likes': targetLikes,
        if (_deadlineController.text.isNotEmpty) 'deadline': _deadlineController.text,
        'is_public': isPublic,
      });
      if (!mounted) return;
      // Pop kembali ke dashboard (akan auto-refresh), lalu push ke active room
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BrandActiveRoomScreen(campaign: campaign)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deadlineController.dispose();
    _capacityController.dispose();
    _rewardController.dispose();
    _briefController.dispose();
    _targetViewsController.dispose();
    _targetLikesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black.withValues(alpha: 0.54), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'New Campaign',
          style: TextStyle(
            color: KonektaColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved!')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text(
                'Draft',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  // Section 1: Campaign Details
                  _buildSectionCard(
                    icon: Icons.campaign_outlined,
                    iconBgColor: const Color(0xFFD2E6FF),
                    iconColor: KonektaColors.primary,
                    title: 'Campaign Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Campaign Name'),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Summer Launch 2024',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            fillColor: Color(0xFFEBF2F9),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFFD2E6FF), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF408CFF), width: 1.2),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        _buildFieldLabel('Deadline'),
                        TextField(
                          controller: _deadlineController,
                          readOnly: true,
                          onTap: _pickDeadline,
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            fillColor: const Color(0xFFEBF2F9),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD2E6FF), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF408CFF), width: 1.2),
                            ),
                          ),
                          style: TextStyle(fontSize: 14, color: _deadlineController.text.isEmpty ? Colors.grey : null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Logistics & Budget
                  _buildSectionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconBgColor: const Color(0xFFD2E6FF),
                    iconColor: KonektaColors.primary,
                    title: 'Logistics & Budget',
                    child: Column(
                      children: [
                        _buildRowInputField(
                          label: 'Room Capacity (Influencer)',
                          hintText: '50',
                          prefixIcon: const Icon(Icons.people_outline, size: 18, color: Colors.grey),
                          controller: _capacityController,
                        ),
                        const SizedBox(height: 14),
                        _buildRowInputField(
                          label: 'Reward Nominal per Creator',
                          hintText: ' Rp   123.000',
                          prefixText: '',
                          controller: _rewardController,
                        ),
                        const SizedBox(height: 14),
                        _buildRowInputField(
                          label: 'Target Total Views',
                          hintText: '100000',
                          prefixIcon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.grey),
                          controller: _targetViewsController,
                        ),
                        const SizedBox(height: 14),
                        _buildRowInputField(
                          label: 'Target Total Likes',
                          hintText: '5000',
                          prefixIcon: const Icon(Icons.favorite_outline, size: 18, color: Colors.grey),
                          controller: _targetLikesController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Video Concept
                  _buildSectionCard(
                    icon: Icons.video_collection_outlined,
                    iconBgColor: const Color(0xFFD2E6FF),
                    iconColor: KonektaColors.primary,
                    title: 'Video Concept',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Brief Instructions'),
                        TextField(
                          controller: _briefController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Describe the aesthetic, key messaging, and any required product shots...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            fillColor: Color(0xFFEBF2F9),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFFD2E6FF), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF408CFF), width: 1.2),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 4: Campaign Target Metrics
                  _buildSectionCard(
                    icon: Icons.bar_chart_outlined,
                    iconBgColor: const Color(0xFFD2E6FF),
                    iconColor: KonektaColors.primary,
                    title: 'Campaign Target Metrics',
                    subtitle: 'Set specific numeric goals for your selected KPIs per influencer.',
                    child: Column(
                      children: [
                        ..._targetMetrics.asMap().entries.map((entry) {
                          final index = entry.key;
                          final metric = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildMetricRowWithRemove(icon: metric['icon'] as IconData, label: metric['label'] as String, value: metric['value'] as String, onRemove: () => _removeTargetMetric(index)),
                          );
                        }),
                        if (_targetMetrics.isNotEmpty) const SizedBox(height: 2),
                        _buildDashedButton(label: 'Add Target Metrics', onTap: _addTargetMetric),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 5: Requirement Metrics
                  _buildSectionCard(
                    icon: Icons.error_outline,
                    iconBgColor: const Color(0xFFD2E6FF),
                    iconColor: KonektaColors.primary,
                    title: 'Requirement Metrics',
                    subtitle: 'Set specific numeric Requirement for the influencer that applies.',
                    child: Column(
                      children: [
                        ..._requirementMetrics.asMap().entries.map((entry) {
                          final index = entry.key;
                          final metric = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildMetricRowWithRemove(icon: metric['icon'] as IconData, label: metric['label'] as String, value: metric['value'] as String, onRemove: () => _removeRequirementMetric(index)),
                          );
                        }),
                        if (_requirementMetrics.isNotEmpty) const SizedBox(height: 2),
                        _buildDashedButton(label: 'Add requirement metrics', onTap: _addRequirementMetric),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 6: Campaign Visibility
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    'Campaign Visibility ',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF232B44)),
                                  ),
                                  Icon(Icons.public, size: 16, color: Color(0xFF408CFF)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
                                  children: [
                                    const TextSpan(text: 'Currently set to '),
                                    TextSpan(
                                      text: isPublic ? 'Public' : 'Private',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000000)),
                                    ),
                                    const TextSpan(text: '. Anyone can discover and apply.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value;
                            });
                          },
                          activeThumbColor: KonektaColors.primary,
                          activeTrackColor: KonektaColors.primary.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Button Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: KonektaGradients.pillBlue,
                ),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                  label: Text(
                    _saving ? 'Creating...' : 'Create Room',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Base Section Card Builder
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF232B44)),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.2),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Row Input Builder (Logistics & Budget)
  Widget _buildRowInputField({
    required String label,
    required String hintText,
    Widget? prefixIcon,
    String? prefixText,
    required TextEditingController controller,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF232B44)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 40,
            child: _buildTextField(
              hintText: hintText,
              prefixIcon: prefixIcon,
              prefixText: prefixText,
              controller: controller,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  // Metrics Row Builder (Target Metrics & Requirements)
  Widget _buildMetricRow({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7A8D9E)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7A8D9E), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const TextField(
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter goal',
                hintStyle: TextStyle(color: Colors.white, fontSize: 12),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metrics Row with Remove Button
  Widget _buildMetricRowWithRemove({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7A8D9E)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7A8D9E), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: value.isEmpty ? 'Enter goal' : null,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Custom Dashed Outline Button Implementation
  Widget _buildDashedButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(color: Color(0xFF7A8D9E).withValues(alpha: 0.6)),
        child: Container(
          width: double.infinity,
          height: 42,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 16, color: Color(0xFF7A8D9E)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF7A8D9E), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Label Builder
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF232B44), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Custom Text Field Builder
  Widget _buildTextField({
    required String hintText,
    Widget? prefixIcon,
    String? prefixText,
    required TextEditingController controller,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF90A3BF), fontSize: 13),
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
        fillColor: const Color(0xFFEBF2F9),
        filled: true,
        contentPadding: contentPadding,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD2E6FF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF408CFF), width: 1.2),
        ),
      ),
    );
  }
}

// Custom Painter for dashed border buttons
class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    double distance = 0.0;
    for (var metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(metric.extractPath(distance, distance + 5), Offset.zero);
        distance += 5 + 4;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
