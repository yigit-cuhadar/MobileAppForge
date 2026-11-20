import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:forge_core/forge_core.dart';
import 'package:http/http.dart' as http;

/// Apple Search Ads attribution of this install: the device's AdServices
/// token sent to Apple's attribution API
/// (https://developer.apple.com/documentation/adservices/aaattribution/attributiontoken()).
/// The token needs no consent or App Tracking Transparency prompt. iOS only.
class AdServicesAttribution {
  AdServicesAttribution({
    http.Client? client,
    this.retryDelay = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Apple's advice for a 404, which means the record is not ready yet:
  /// try again every 5 seconds, three attempts at most.
  final Duration retryDelay;

  static const _channel = MethodChannel('forge_purchases/ad_services');
  static final _endpoint = Uri.parse(
    'https://api-adservices.apple.com/api/v1/',
  );
  static const _attempts = 3;

  /// The Apple Search Ads campaign this install came from; null when Apple
  /// attributes it to none, or the device has no token (before iOS 14.3, a
  /// simulator). A developer-mode device gets Apple's test record, campaign
  /// 1234567890. Throws a [NetworkFailure] when Apple cannot be reached or
  /// has no record yet.
  Future<int?> campaignId() async {
    final token = await _channel.invokeMethod<String>('attributionToken');
    if (token == null) return null;
    for (var attempt = 1; ; attempt++) {
      final http.Response response;
      try {
        response = await _client.post(
          _endpoint,
          headers: {'Content-Type': 'text/plain'},
          body: token,
        );
      } on http.ClientException catch (error) {
        throw NetworkFailure('AdServices unreachable', error);
      }
      final status = response.statusCode;
      if (status == 404 && attempt < _attempts) {
        await Future<void>.delayed(retryDelay);
        continue;
      }
      if (status == 404 || status >= 500) {
        throw NetworkFailure('AdServices answered $status');
      }
      // 400: a token Apple rejects, a bug worth logging.
      if (status != 200) throw StateError('AdServices answered $status');
      final record = jsonDecode(response.body) as Map<String, Object?>;
      return record['attribution'] == true
          ? (record['campaignId'] as num?)?.toInt()
          : null;
    }
  }
}
