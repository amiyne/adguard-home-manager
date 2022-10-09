// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/clients/client_modal.dart';

import 'package:adguard_home_manager/models/clients.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/models/clients_allowed_blocked.dart';
import 'package:adguard_home_manager/classes/process_modal.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';

class ClientsFab extends StatelessWidget {
  final int tab;

  const ClientsFab({
    Key? key,
    required this.tab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    void confirmRemoveDomain(String ip) async {
      Map<String, List<String>> body = {};

      final List<String> clients = [...serversProvider.clients.data!.clientsAllowedBlocked?.disallowedClients ?? [], ip];
      body = {
        "allowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.allowedClients ?? [],
        "disallowed_clients": clients,
        "blocked_hosts": serversProvider.clients.data!.clientsAllowedBlocked?.blockedHosts ?? [],
      };

      ProcessModal processModal = ProcessModal(context: context);
      processModal.open(AppLocalizations.of(context)!.addingClient);

      final result = await requestAllowedBlockedClientsHosts(serversProvider.selectedServer!, body);

      processModal.close();

      if (result['result'] == 'success') {
        serversProvider.setAllowedDisallowedClientsBlockedDomains(
          ClientsAllowedBlocked(
            allowedClients: body['allowed_clients'] ?? [], 
            disallowedClients: body['disallowed_clients'] ?? [], 
            blockedHosts: body['blocked_hosts'] ?? [], 
          )
        );
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientAddedSuccessfully),
            backgroundColor: Colors.green,
          )
        );
      }
      else if (result['result'] == 'error' && result['message'] == 'client_another_list') {
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientAnotherList),
            backgroundColor: Colors.red,
          )
        );
      }
      else {
        appConfigProvider.addLog(result['log']);
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientNotAdded),
            backgroundColor: Colors.red,
          )
        );
      }
    }

    void confirmAddClient(Client client) async {
      ProcessModal processModal = ProcessModal(context: context);
      processModal.open(AppLocalizations.of(context)!.addingClient);
      
      final result = await postAddClient(server: serversProvider.selectedServer!, data: client.toJson());
      
      processModal.close();

      if (result['result'] == 'success') {
        ClientsData clientsData = serversProvider.clients.data!;
        clientsData.clients.add(client);
        serversProvider.setClientsData(clientsData);
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientAddedSuccessfully),
            backgroundColor: Colors.green,
          )
        );
      }
      else {
        appConfigProvider.addLog(result['log']);
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientNotAdded),
            backgroundColor: Colors.red,
          )
        );
      }
    }

    void openAddClient() {
      showFlexibleBottomSheet(
        minHeight: 0.6,
        initHeight: 0.6,
        maxHeight: 0.95,
        isCollapsible: true,
        duration: const Duration(milliseconds: 250),
        anchors: [0.95],
        context: context, 
        builder: (ctx, controller, offset) => ClientModal(
          scrollController: controller,
          onConfirm: confirmAddClient
        ),
        bottomSheetColor: Colors.transparent
      );
    }

    return FloatingActionButton(
      onPressed: () => openAddClient(),
      child: const Icon(Icons.add),
    );
  }
}