import '../../core/api_client.dart';
import '../models/influencer_summary.dart';

class DashboardRepository {
  final ApiClient api;
  DashboardRepository(this.api);

  Future<InfluencerSummary> influencerSummary() async {
    final data = await api.get('/dashboard/influencer');
    return InfluencerSummary.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
