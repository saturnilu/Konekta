import 'campaign.dart';

// Safe parse: handles String ("0.00"), int, double from MySQL
num _n(dynamic v, [num fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? fallback;
}

int _i(dynamic v, [int fallback = 0]) => _n(v, fallback).toInt();

class InfluencerSummary {
  final num audienceReached;
  final num engagementRate;
  final num totalInteractions;
  final int completedCampaigns;
  final int activeCampaigns;
  final int pendingProposals;
  final num thisMonthEarnings;
  final num pendingEarnings;
  final num totalViews;
  final num totalLikes;
  final List<Campaign> activeCampaignsList;

  InfluencerSummary({
    required this.audienceReached,
    required this.engagementRate,
    required this.totalInteractions,
    required this.completedCampaigns,
    required this.activeCampaigns,
    required this.pendingProposals,
    required this.thisMonthEarnings,
    required this.pendingEarnings,
    required this.totalViews,
    required this.totalLikes,
    this.activeCampaignsList = const [],
  });

  factory InfluencerSummary.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final list = (json['active_campaigns'] as List?)
            ?.map((e) => Campaign.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <Campaign>[];
    return InfluencerSummary(
      audienceReached:     _n(summary['audience_reached']),
      engagementRate:      _n(summary['engagement_rate']),
      totalInteractions:   _n(summary['total_interactions']),
      completedCampaigns:  _i(summary['completed_campaigns']),
      activeCampaigns:     _i(summary['active_campaigns']),
      pendingProposals:    _i(summary['pending_proposals']),
      thisMonthEarnings:   _n(summary['this_month_earnings']),
      pendingEarnings:     _n(summary['pending_earnings']),
      totalViews:          _n(summary['total_views']),
      totalLikes:          _n(summary['total_likes']),
      activeCampaignsList: list,
    );
  }
}
