import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models/subscription.dart' as model;

class InfluencerSubscriptionScreen extends StatefulWidget {
  const InfluencerSubscriptionScreen({super.key});

  @override
  State<InfluencerSubscriptionScreen> createState() => _InfluencerSubscriptionScreenState();
}

class _InfluencerSubscriptionScreenState extends State<InfluencerSubscriptionScreen> {
  List<model.SubscriptionPlan> _plans = [];
  model.Subscription? _current;
  bool _loading = true;
  bool _mutating = false;
  int? _busyPlanId;
  String? _error;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final results = await Future.wait([
        scope.subscriptionRepo.plans(),
        scope.subscriptionRepo.current(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<model.SubscriptionPlan>;
        _current = results[1] as model.Subscription?;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load subscription: $e';
        _loading = false;
      });
    }
  }

  Future<void> _choosePlan(model.SubscriptionPlan plan) async {
    if (_mutating) return;
    if (_current != null && _current!.planId == plan.id && _current!.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already on the ${plan.name} plan')),
      );
      return;
    }
    setState(() {
      _mutating = true;
      _busyPlanId = plan.id;
    });
    try {
      final scope = AppScope.of(context);
      final updated = await scope.subscriptionRepo.checkout(plan.id);
      if (!mounted) return;
      setState(() => _current = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are now on the ${updated.planName} plan')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _mutating = false;
          _busyPlanId = null;
        });
      }
    }
  }

  Future<void> _cancel() async {
    if (_current == null || !_current!.isActive) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text('You will lose premium features when your current period ends.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep plan')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel', style: TextStyle(color: KonektaColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _mutating = true);
    try {
      final scope = AppScope.of(context);
      final updated = await scope.subscriptionRepo.cancel();
      if (!mounted) return;
      setState(() => _current = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektaColors.bg,
      appBar: AppBar(
        backgroundColor: KonektaColors.surface,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: KonektaColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Subscription Plans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: KonektaColors.textPrimary),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _CurrentPlanCard(current: _current, onCancel: _cancel, mutating: _mutating),
          const SizedBox(height: 18),
          const Text('Choose a plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
          const SizedBox(height: 4),
          const Text('Upgrade your account to unlock premium features.',
              style: TextStyle(fontSize: 12, color: KonektaColors.textSecondary)),
          const SizedBox(height: 14),
          if (_plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: const [
                  Icon(Icons.workspace_premium_outlined, size: 56, color: KonektaColors.textMuted),
                  SizedBox(height: 8),
                  Text('No plans available right now',
                      style: TextStyle(color: KonektaColors.textMuted, fontSize: 13)),
                ],
              ),
            )
          else
            ..._plans.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: p,
                    isCurrent: _current?.planId == p.id && _current!.isActive,
                    busy: _busyPlanId == p.id,
                    disabled: _mutating,
                    onChoose: () => _choosePlan(p),
                  ),
                )),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final model.Subscription? current;
  final VoidCallback onCancel;
  final bool mutating;
  const _CurrentPlanCard({required this.current, required this.onCancel, required this.mutating});

  @override
  Widget build(BuildContext context) {
    final hasActive = current != null && current!.isActive;
    final name = current?.planName ?? 'No active plan';
    final status = current?.status ?? 'inactive';
    final expires = current?.expiresAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: KonektaGradients.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: KonektaColors.primary.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text('Current plan',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (hasActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('ACTIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            hasActive
                ? 'Status: ${status} • Renews ${Format.date(expires)}'
                : 'Pick a plan below to unlock premium features.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (hasActive) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: 150,
              child: OutlinedButton.icon(
                onPressed: mutating ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.white),
                label: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final model.SubscriptionPlan plan;
  final bool isCurrent;
  final bool busy;
  final bool disabled;
  final VoidCallback onChoose;
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.busy,
    required this.disabled,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final priceVal = plan.price ?? 0;
    final currency = plan.currency ?? 'IDR';
    final duration = plan.durationMonths ?? 0;
    final isFree = priceVal <= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isCurrent ? Border.all(color: KonektaColors.primary, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: KonektaColors.textDark)),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KonektaColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('CURRENT',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFree ? 'Free' : Format.currency(priceVal),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KonektaColors.primary),
              ),
              if (!isFree && currency.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(currency,
                      style: const TextStyle(color: KonektaColors.textMuted, fontSize: 11)),
                ),
              ],
              if (duration > 0) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('/ $duration month${duration == 1 ? '' : 's'}',
                      style: const TextStyle(color: KonektaColors.textMuted, fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: KonektaColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f,
                          style: const TextStyle(fontSize: 12, color: KonektaColors.textSecondary, height: 1.3)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (disabled || isCurrent) ? null : onChoose,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? KonektaColors.success : null,
              ),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isCurrent ? 'Active' : (isFree ? 'Use Free Plan' : 'Choose Plan'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: KonektaColors.danger, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: KonektaColors.textSecondary)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
