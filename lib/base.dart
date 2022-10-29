// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:install_plugin_v2/install_plugin_v2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:store_checker/store_checker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/widgets/bottom_nav_bar.dart';
import 'package:adguard_home_manager/widgets/update_modal.dart';
import 'package:adguard_home_manager/widgets/download_modal.dart';

import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/models/github_release.dart';
import 'package:adguard_home_manager/constants/package_name.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/functions/snackbar.dart';
import 'package:adguard_home_manager/models/app_screen.dart';
import 'package:adguard_home_manager/config/app_screens.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';

class Base extends StatefulWidget {
  final AppConfigProvider appConfigProvider;

  const Base({
    Key? key,
    required this.appConfigProvider,
  }) : super(key: key);

  @override
  State<Base> createState() => _BaseState();
}

class _BaseState extends State<Base> with WidgetsBindingObserver {
  int selectedScreen = 0;

  Future<GitHubRelease?> checkInstallationSource() async {
    Source installationSource = await StoreChecker.getSource;
    if (installationSource != Source.IS_INSTALLED_FROM_PLAY_STORE) {
      final result = await checkAppUpdatesGitHub();
      if (result['result'] == 'success') {
        if (result['body'].tagName != widget.appConfigProvider.getAppInfo!.version) {
          return result['body'];
        }
      }
    }
    return null;
  }

  Future<bool> managePermission() async {
    try {
      if (await Permission.storage.isGranted) {
        return true;
      }
      else {
        final PermissionStatus status = await Permission.storage.request();
        if (status.isGranted == false) {
          return false;
        }
        else {
          return true;
        }
      }
    } catch (e) {
      return false;
    }
  } 

  void installApk(String path) async {
    final granted = await managePermission();

    if (granted == true) {
      path = path.replaceFirst(r'file://', '');

      final file = File(path);
      final exists = await file.exists();   

      if (exists) {
        InstallPlugin.installApk(
          path, PackageName.packageName
        );
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      void download(String link, String version) async {
        final granted = await managePermission();
        if (granted == true) {
          showDialog(
            context: context, 
            builder: (context) => DownloadModal(
              url: link,
              version: version,
              onFinish: installApk,
            ),
            barrierDismissible: false
          );
        }
        else {
          showSnacbkar(
            context: context, 
            appConfigProvider: widget.appConfigProvider, 
            label: AppLocalizations.of(context)!.permissionNotGranted, 
            color: Colors.red
          );
        }
      }

      final result = await checkInstallationSource();

      if (result != null) {
        await showDialog(
          context: context, 
          builder: (context) => UpdateModal(
            gitHubRelease: result,
            onDownload: download,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    List<AppScreen> screens = serversProvider.selectedServer != null
      ? screensServerConnected 
      : screensSelectServer;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Theme.of(context).brightness == Brightness.light
          ? Brightness.light
          : Brightness.dark,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
      ),
      child: Scaffold(
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (
            (child, primaryAnimation, secondaryAnimation) => FadeThroughTransition(
              animation: primaryAnimation, 
              secondaryAnimation: secondaryAnimation,
              child: child,
            )
          ),
          child: screens[appConfigProvider.selectedScreen].body,
        ),
        bottomNavigationBar: const BottomNavBar(),
      )
    );
  }
}