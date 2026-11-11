// Payloads in the shape the RevenueCat plugin hands to its `fromJson`
// factories (purchases_flutter 11), for the App Store and Google Play.

Map<String, Object?> entitlementJson({
  required String store,
  required String productId,
  String? basePlanId,
  bool isActive = true,
  bool willRenew = true,
  String periodType = 'NORMAL',
  String expiration = '2027-01-01T00:00:00.000Z',
  String? billingIssueDetectedAt,
}) => {
  'identifier': 'premium',
  'isActive': isActive,
  'willRenew': willRenew,
  'latestPurchaseDate': '2026-01-01T00:00:00.000Z',
  'originalPurchaseDate': '2026-01-01T00:00:00.000Z',
  'productIdentifier': productId,
  'isSandbox': true,
  'ownershipType': 'PURCHASED',
  'store': store,
  'periodType': periodType,
  'expirationDate': expiration,
  'unsubscribeDetectedAt': null,
  'billingIssueDetectedAt': billingIssueDetectedAt,
  'productPlanIdentifier': basePlanId,
  'verification': 'NOT_REQUESTED',
};

Map<String, Object?> customerInfoJson([
  List<Map<String, Object?>> entitlements = const [],
]) => {
  'entitlements': {
    'all': {for (final e in entitlements) e['identifier']: e},
    'active': {
      for (final e in entitlements)
        if (e['isActive'] == true) e['identifier']: e,
    },
    'verification': 'NOT_REQUESTED',
  },
  'allPurchaseDates': <String, Object?>{},
  'activeSubscriptions': <String>[],
  'allPurchasedProductIdentifiers': <String>[],
  'nonSubscriptionTransactions': <Object>[],
  'firstSeen': '2026-01-01T00:00:00.000Z',
  'originalAppUserId': 'user',
  'allExpirationDates': <String, Object?>{},
  'requestDate': '2026-01-01T00:00:00.000Z',
  'latestExpirationDate': null,
  'originalPurchaseDate': null,
  'managementURL': null,
  'subscriptionsByProductIdentifier': <String, Object?>{},
};

/// The App Store's 1-week free trial.
const appStoreWeekTrial = {
  'price': 0.0,
  'priceString': '€0.00',
  'period': 'P1W',
  'cycles': 1,
  'periodUnit': 'WEEK',
  'periodNumberOfUnits': 1,
};

/// Google Play's 7-day free trial phase.
const playSevenDayTrial = {
  'price': 0.0,
  'priceString': '€0.00',
  'period': 'P7D',
  'cycles': 1,
  'periodUnit': 'DAY',
  'periodNumberOfUnits': 7,
};

Map<String, Object?> packageJson({
  required String productId,
  String packageType = 'ANNUAL',
  String? subscriptionPeriod = 'P1Y',
  Map<String, Object?>? introPrice,
}) => {
  'identifier': r'$rc_annual',
  'packageType': packageType,
  'product': {
    'identifier': productId,
    'description': 'Pro',
    'title': 'Pro',
    'price': 39.99,
    'priceString': '€39.99',
    'currencyCode': 'EUR',
    'introPrice': introPrice,
    'productCategory': 'SUBSCRIPTION',
    'subscriptionPeriod': subscriptionPeriod,
  },
  'presentedOfferingContext': {
    'offeringIdentifier': 'default',
    'placementIdentifier': null,
    'targetingContext': null,
  },
};

Map<String, Object?> offeringsJson(List<Map<String, Object?>> packages) {
  final offering = {
    'identifier': 'default',
    'serverDescription': '',
    'metadata': <String, Object>{},
    'availablePackages': packages,
  };
  return {
    'all': {'default': offering},
    'current': offering,
  };
}
