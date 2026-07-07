import '../../core/api_client.dart';
import '../models/brand.dart';
import '../models/influencer.dart';

// Extract list from either a flat List or { items: [...] } response
List<Map> _extractList(dynamic data) {
  if (data is List) return data.cast<Map>();
  if (data is Map) {
    final items = data['items'];
    if (items is List) return items.cast<Map>();
  }
  return const [];
}

class DiscoveryRepository {
  final ApiClient api;
  DiscoveryRepository(this.api);

  Future<List<InfluencerProfile>> influencers({
    String? q,
    String? niche,
    String? location,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await api.get('/influencers', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (niche != null && niche.isNotEmpty) 'niche': niche,
      if (location != null && location.isNotEmpty) 'location': location,
      'page': page,
      'limit': limit,
    });
    return _extractList(data)
        .map((e) => InfluencerProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<InfluencerProfile> influencer(int id) async {
    final data = await api.get('/influencers/$id');
    return InfluencerProfile.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Brand>> brands({
    String? q,
    String? industry,
    String? location,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await api.get('/brands', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (location != null && location.isNotEmpty) 'location': location,
      'page': page,
      'limit': limit,
    });
    return _extractList(data)
        .map((e) => Brand.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Brand> brand(int id) async {
    final data = await api.get('/brands/$id');
    return Brand.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
