import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


Map<String, dynamic> getFilteredStatus(BuildContext context, String filterKey) {
  switch (filterKey) {
    case 'NotFilteredNotFound':
      return {
        'filtered': false,
        'label': AppLocalizations.of(context)!.processed,
        'color': Colors.green,
        'icon': Icons.verified_user_rounded,
      };

    case 'NotFilteredWhiteList':
      return {
        'filtered': false,
        'label': AppLocalizations.of(context)!.processedWhitelist,
        'color': Colors.green,
        'icon': Icons.verified_user_rounded,
      };

    case 'NotFilteredError':
      return {
        'filtered': false,
        'label': AppLocalizations.of(context)!.processedError,
        'color': Colors.green,
        'icon': Icons.verified_user_rounded,
      };

    case 'FilteredBlackList':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.blockedBlacklist,
        'color': Colors.red,
        'icon': Icons.gpp_bad_rounded,
      };

    case 'FilteredSafeBrowsing':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.blockedSafeBrowsing,
        'color': Colors.red,
        'icon': Icons.gpp_bad_rounded,
      };

    case 'FilteredParental':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.blockedParental,
        'color': Colors.red,
        'icon': Icons.gpp_bad_rounded,
      };

    case 'FilteredInvalid':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.blockedInvalid,
        'color': Colors.red,
        'icon': Icons.gpp_bad_rounded,
      };

    case 'FilteredSafeSearch':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.blockedSafeSearch,
        'color': Colors.red,
        'icon': Icons.gpp_bad_rounded,
      };

    case 'FilteredBlockedService':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.blockedService,
        'color': Colors.red,
        'icon': Icons.gpp_bad_rounded,
      };

    case 'Rewrite':
    case 'RewriteEtcHosts':
    case 'RewriteRule':
      return {
        'filtered': true,
        'label': AppLocalizations.of(context)!.rewrite,
        'color': Colors.blue,
        'icon': Icons.shield_rounded,
      };

    default:
      return {'filtered': null, 'label': 'Unknown'};
  }
}