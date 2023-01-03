// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adguard_home_manager/models/dhcp.dart';
import 'package:adguard_home_manager/models/dns_info.dart';
import 'package:adguard_home_manager/models/encryption.dart';
import 'package:adguard_home_manager/models/filtering.dart';
import 'package:adguard_home_manager/models/github_release.dart';
import 'package:adguard_home_manager/models/logs.dart';
import 'package:adguard_home_manager/models/filtering_status.dart';
import 'package:adguard_home_manager/models/app_log.dart';
import 'package:adguard_home_manager/models/rewrite_rules.dart';
import 'package:adguard_home_manager/models/server_info.dart';
import 'package:adguard_home_manager/models/server_status.dart';
import 'package:adguard_home_manager/models/clients.dart';
import 'package:adguard_home_manager/models/clients_allowed_blocked.dart';
import 'package:adguard_home_manager/models/server.dart';
import 'package:adguard_home_manager/constants/urls.dart';


Future<Map<String, dynamic>> apiRequest({
  required Server server, 
  required String method, 
  required String urlPath, 
  dynamic body,
  required String type,
  bool? overrideTimeout,
}) async {
  final String connectionString = "${server.connectionMethod}://${server.domain}${server.port != null ? ':${server.port}' : ""}${server.path ?? ""}/control$urlPath";
  try {
    HttpClient httpClient = HttpClient();
    if (method == 'get') {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(connectionString));
      request.headers.set('Authorization', 'Basic ${server.authToken}');
      HttpClientResponse response = overrideTimeout == true 
        ? await request.close()
        : await request.close().timeout(const Duration(seconds: 10));
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();
      if (response.statusCode == 200) {
        return {
          'hasResponse': true,
          'error': false,
          'statusCode': response.statusCode,
          'body': reply
        };
      }
      else {
        return {
          'hasResponse': true,
          'error': true,
          'statusCode': response.statusCode,
          'body': reply
        };
      }    
    }
    else if (method == 'post') {
      HttpClientRequest request = await httpClient.postUrl(Uri.parse(connectionString));
      request.headers.set('Authorization', 'Basic ${server.authToken}');
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(json.encode(body)));
      HttpClientResponse response = overrideTimeout == true 
        ? await request.close()
        : await request.close().timeout(const Duration(seconds: 10));
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();
      if (response.statusCode == 200) {
        return {
          'hasResponse': true,
          'error': false,
          'statusCode': response.statusCode,
          'body': reply
        };
      }
      else {
        return {
          'hasResponse': true,
          'error': true,
          'statusCode': response.statusCode,
          'body': reply
        };
      }    
    }
    else {
      throw Exception('Method is required');
    }
  } on SocketException {
    return {
      'result': 'no_connection', 
      'message': 'SocketException',
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: 'SocketException'
      )
    };
  } on TimeoutException {
    return {
      'result': 'no_connection', 
      'message': 'TimeoutException',
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: 'TimeoutException'
      )
    };
  } on HandshakeException {
    return {
      'result': 'ssl_error', 
      'message': 'HandshakeException',
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: 'HandshakeException'
      )
    };
  } catch (e) {
    return {
      'result': 'error', 
      'message': e.toString(),
      'log': AppLog(
        type: type, 
        dateTime: DateTime.now(), 
        message: e.toString()
      )
    };
  }
}

Future login(Server server) async {
  final result = await apiRequest(
    server: server,
    method: 'post',
    urlPath: '/login', 
    body: {
      "name": server.user,
      "password": server.password
    },
    type: 'login'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else if (result['statusCode'] == 400 || result['statusCode'] == 401 || result['statusCode'] == 403) {
      return {
        'result': 'invalid_username_password',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'invalid_username_password',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
    else if (result['statusCode'] == 429) {
      return {
        'result': 'many_attempts',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'many_attempts',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
    else if (result['statusCode'] == 500) {
      return {
        'result': 'server_error',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'server_error',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future loginHA(Server server) async {
  final result = await apiRequest(
    server: server,
    method: 'get',
    urlPath: '/status', 
    type: 'login_ha'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else if (result['statusCode'] == 401 || result['statusCode'] == 403) {
      return {
        'result': 'invalid_username_password',
        'log': AppLog(
          type: 'login', 
          dateTime: DateTime.now(), 
          message: 'invalid_username_password',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'login_ha', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getServerStatus(Server server) async {
  final result = await Future.wait([
    apiRequest(server: server, method: 'get', urlPath: '/stats', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/filtering/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/safesearch/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/safebrowsing/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/parental/status', type: 'server_status'),
    apiRequest(server: server, method: 'get', urlPath: '/clients', type: 'server_status'),
  ]);

  if (
    result[0]['hasResponse'] == true &&
    result[1]['hasResponse'] == true &&
    result[2]['hasResponse'] == true &&
    result[3]['hasResponse'] == true &&
    result[4]['hasResponse'] == true &&
    result[5]['hasResponse'] == true &&
    result[6]['hasResponse'] == true
  ) {
    if (
      result[0]['statusCode'] == 200 &&
      result[1]['statusCode'] == 200 &&
      result[2]['statusCode'] == 200 &&
      result[3]['statusCode'] == 200 &&
      result[4]['statusCode'] == 200 &&
      result[5]['statusCode'] == 200 &&
      result[6]['statusCode'] == 200 
    ) {
      final Map<String, dynamic> mappedData = {
        'stats': jsonDecode(result[0]['body']),
        'clients': jsonDecode(result[6]['body'])['clients'],
        'generalEnabled': jsonDecode(result[1]['body']),
        'filtering': jsonDecode(result[2]['body']),
        'safeSearchEnabled': jsonDecode(result[3]['body']),
        'safeBrowsingEnabled': jsonDecode(result[4]['body']),
        'parentalControlEnabled': jsonDecode(result[5]['body']),
      };
      return {
        'result': 'success',
        'data': ServerStatusData.fromJson(mappedData)
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_server_status', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode']).toString(),
          resBody: result.map((res) => res['body']).toString()
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'get_server_status', 
        dateTime: DateTime.now(), 
        message: 'no_response',
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString()
      )
    };
  }
}

Future updateFiltering(Server server, bool enable) async {
  final result = await apiRequest(
    urlPath: '/filtering/config', 
    method: 'post',
    server: server, 
    body: {
      'enabled': enable
    },
    type: 'update_filtering'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_filtering', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateSafeSearch(Server server, bool enable) async {
  final result = enable == true 
    ? await apiRequest(
        urlPath: '/safesearch/enable', 
        method: 'post',
        server: server, 
        type: 'enable_safe_search'
      )
    : await apiRequest(
        urlPath: '/safesearch/disable', 
        method: 'post',
        server: server,
        type: 'disable_safe_search'
      );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'safe_search', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateSafeBrowsing(Server server, bool enable) async {
  final result = enable == true 
    ? await apiRequest(
        urlPath: '/safebrowsing/enable', 
        method: 'post',
        server: server, 
        type: 'enable_safe_browsing'
      )
    : await apiRequest(
        urlPath: '/safebrowsing/disable', 
        method: 'post',
        server: server, 
        type: 'disable_safe_browsing'
      );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'safe_browsing', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateParentalControl(Server server, bool enable) async {
  final result = enable == true 
    ? await apiRequest(
        urlPath: '/parental/enable', 
        method: 'post',
        server: server, 
        type: 'enable_parental_control'
      )
    : await apiRequest(
        urlPath: '/parental/disable', 
        method: 'post',
        server: server, 
        type: 'disable_parental_control'
      );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'parental_control', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateGeneralProtection(Server server, bool enable) async {
    final result = await apiRequest(
    urlPath: '/dns_config', 
    method: 'post',
    server: server, 
    body: {
      'protection_enabled': enable
    },
    type: 'general_protection'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'general_protection', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getClients(Server server) async {
  final result = await Future.wait([
    apiRequest(server: server, method: 'get', urlPath: '/clients', type: 'get_clients'),
    apiRequest(server: server, method: 'get', urlPath: '/access/list', type: 'get_clients'),
  ]);

  if (result[0]['hasResponse'] == true && result[1]['hasResponse'] == true) {
    if (result[0]['statusCode'] == 200 && result[1]['statusCode'] == 200) {
      final clients = ClientsData.fromJson(jsonDecode(result[0]['body']));
      clients.clientsAllowedBlocked = ClientsAllowedBlocked.fromJson(jsonDecode(result[1]['body']));
      return {
        'result': 'success',
        'data': clients
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_clients', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
          resBody: result.map((res) => res['body'] ?? 'null').toString(),
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'get_clients', 
        dateTime: DateTime.now(), 
        message: 'no_response',
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString(),
      )
    };
  }
}

Future requestAllowedBlockedClientsHosts(Server server, Map<String, List<String>?> body) async {
  final result = await apiRequest(
    urlPath: '/access/set', 
    method: 'post',
    server: server, 
    body: body,
    type: 'get_clients'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    if (result['statusCode'] == 400) {
      return {
        'result': 'error',
        'message': 'client_another_list'
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_clients', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getLogs({
  required Server server, 
  required int count, 
  int? offset,
  DateTime? olderThan,
  String? responseStatus,
  String? search
}) async {
  final result = await apiRequest(
    server: server, 
    method: 'get', 
    urlPath: '/querylog?limit=$count${offset != null ? '&offset=$offset' : ''}${olderThan != null ? '&older_than=${olderThan.toIso8601String()}' : ''}${responseStatus != null ? '&response_status=$responseStatus' : ''}${search != null ? '&search=$search' : ''}',
    type: 'get_logs'
  );
    
  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': LogsData.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error', 
        'log': AppLog(
          type: 'get_logs', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getFilteringRules({
  required Server server, 
}) async {
  final result = await apiRequest(
    server: server, 
    method: 'get', 
    urlPath: '/filtering/status',
    type: 'get_filtering_rules'
  );
    
  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': FilteringStatus.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error', 
        'log': AppLog(
          type: 'get_filtering_rules', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postFilteringRules({
  required Server server, 
  required Map<String, List<String>> data, 
}) async {
    final result = await apiRequest(
    urlPath: '/filtering/set_rules', 
    method: 'post',
    server: server, 
    body: data,
    type: 'post_filering_rules'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'post_filtering_rules', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postAddClient({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
    final result = await apiRequest(
    urlPath: '/clients/add', 
    method: 'post',
    server: server, 
    body: data,
    type: 'add_client'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'add_client', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postUpdateClient({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
    final result = await apiRequest(
    urlPath: '/clients/update', 
    method: 'post',
    server: server, 
    body: data,
    type: 'update_client'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_client', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future postDeleteClient({
  required Server server, 
  required String name, 
}) async {
  final result = await apiRequest(
    urlPath: '/clients/delete', 
    method: 'post',
    server: server, 
    body: {'name': name},
    type: 'remove_client'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'remove_client', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getFiltering({
  required Server server, 
}) async {
  final result = await Future.wait([
    apiRequest(
      urlPath: '/filtering/status', 
      method: 'get',
      server: server, 
      type: 'get_filtering_status'
    ),
    apiRequest(
      urlPath: '/blocked_services/list', 
      method: 'get',
      server: server, 
      type: 'get_filtering_status'
    ),
  ]);

  if (result[0]['hasResponse'] == true && result[0]['hasResponse'] == true) {
    if (result[0]['statusCode'] == 200 && result[0]['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': FilteringData.fromJson({
          ...jsonDecode(result[0]['body']),
          "blocked_services": jsonDecode(result[1]['body']),
        })
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_filtering_status', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
          resBody: result.map((res) => res['body'] ?? 'null').toString(),
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'get_filtering_status', 
        dateTime: DateTime.now(), 
        message: 'no_response',
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString(),
      )
    };
  }
}

Future setCustomRules({
  required Server server, 
  required List<String> rules, 
}) async {
  final result = await apiRequest(
    urlPath: '/filtering/set_rules', 
    method: 'post',
    server: server, 
    body: {'rules': rules},
    type: 'set_custom_rules'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'set_custom_rules', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }

}

Future addFilteringList({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
  final result = await apiRequest(
    urlPath: '/filtering/add_url', 
    method: 'post',
    server: server, 
    body: data,
    type: 'add_filtering_url'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': result['body']
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'add_filtering_url', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateFilterList({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
  final result = await apiRequest(
    urlPath: '/filtering/set_url', 
    method: 'post',
    server: server, 
    body: data,
    type: 'update_filter_list'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_filter_list', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future deleteFilterList({
  required Server server, 
  required Map<String, dynamic> data, 
}) async {
  final result = await apiRequest(
    urlPath: '/filtering/remove_url', 
    method: 'post',
    server: server, 
    body: data,
    type: 'delete_filter_list'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'delete_filter_list', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getServerInfo({
  required Server server, 
}) async {
  final result = await apiRequest(
    urlPath: '/status', 
    method: 'get',
    server: server, 
    type: 'server_info'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': ServerInfoData.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'server_info', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body']
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateLists({
  required Server server, 
}) async {
  final result = await Future.wait([
    apiRequest(
      urlPath: '/filtering/refresh', 
      method: 'post',
      server: server, 
      body: {'whitelist': true},
      type: 'update_lists',
      overrideTimeout: true
    ),
    apiRequest(
      urlPath: '/filtering/refresh', 
      method: 'post',
      server: server, 
      body: {'whitelist': false},
      type: 'update_lists',
      overrideTimeout: true
    ),
  ]);

  if (result[0]['hasResponse'] == true && result[1]['hasResponse'] == true) {
    if (result[0]['statusCode'] == 200 && result[1]['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': {'updated': jsonDecode(result[0]['body'])['updated']+jsonDecode(result[1]['body'])['updated']} 
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_lists', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
          resBody: result.map((res) => res['body'] ?? 'null').toString(),
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'update_lists', 
        dateTime: DateTime.now(), 
        message: [result[0]['message'], result[1]['message']].toString(),
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString(),
      )
    };
  }
}

Future checkHostFiltered({
  required Server server, 
  required String host,
}) async {
  final result = await apiRequest(
    urlPath: '/filtering/check_host?name=$host', 
    method: 'get',
    server: server, 
    type: 'check_host_filtered'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': jsonDecode(result['body'])
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_lists', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future requestChangeUpdateFrequency({
  required Server server, 
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/filtering/config', 
    method: 'post',
    server: server, 
    body: data,
    type: 'change_update_frequency'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'change_update_frequency', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future setBlockedServices({
  required Server server, 
  required List<String> data,
}) async {
  final result = await apiRequest(
    urlPath: '/blocked_services/set', 
    method: 'post',
    server: server, 
    body: data,
    type: 'update_blocked_services'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_blocked_services', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getDhcpData({
  required Server server, 
}) async {
  final result = await Future.wait([
    apiRequest(
      urlPath: '/dhcp/interfaces', 
      method: 'get',
      server: server, 
      type: 'get_dhcp_data'
    ),
    apiRequest(
      urlPath: '/dhcp/status', 
      method: 'get',
      server: server, 
      type: 'get_dhcp_data'
    ),
  ]);

  if (result[0]['hasResponse'] == true && result[1]['hasResponse'] == true) {
    if (result[0]['statusCode'] == 200 && result[1]['statusCode'] == 200) {
      List<NetworkInterface> interfaces = List<NetworkInterface>.from(jsonDecode(result[0]['body']).entries.map((entry) => NetworkInterface.fromJson(entry.value)));

      return {
        'result': 'success',
        'data': DhcpData(
          networkInterfaces: interfaces, 
          dhcpStatus: DhcpStatus.fromJson(jsonDecode(result[1]['body']))
        )
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_dhcp_data', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
          resBody: result.map((res) => res['body'] ?? 'null').toString(),
        )
      };
    }
  }
  else {
    return {
      'result': 'error',
      'log': AppLog(
        type: 'get_dhpc_data', 
        dateTime: DateTime.now(), 
        message: [result[0]['log'].message, result[1]['log'].message].toString(),
        statusCode: result.map((res) => res['statusCode'] ?? 'null').toString(),
        resBody: result.map((res) => res['body'] ?? 'null').toString(),
      )
    };
  }
}

Future saveDhcpConfig({
  required Server server, 
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/dhcp/set_config', 
    method: 'post',
    server: server, 
    body: data,
    type: 'save_dhcp_config'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'save_dhcp_config', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future resetDhcpConfig({
  required Server server, 
}) async {
  final result = await apiRequest(
    urlPath: '/dhcp/reset', 
    method: 'post',
    server: server, 
    body: {},
    type: 'reset_dhcp_config'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'reset_dhcp_config', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future deleteStaticLease({
  required Server server, 
  required Map<String, dynamic> data
}) async {
  final result = await apiRequest(
    urlPath: '/dhcp/remove_static_lease', 
    method: 'post',
    server: server, 
    body: data,
    type: 'remove_static_lease'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'remove_static_lease', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future createStaticLease({
  required Server server, 
  required Map<String, dynamic> data
}) async {
  final result = await apiRequest(
    urlPath: '/dhcp/add_static_lease', 
    method: 'post',
    server: server, 
    body: data,
    type: 'add_static_lease'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else if (result['statusCode'] == 400 && result['body'].contains('static lease already exists')) {
      return {
        'result': 'error',
        'message': 'already_exists',
        'log': AppLog(
          type: 'add_static_lease', 
          dateTime: DateTime.now(), 
          message: 'already_exists',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
    else if (result['statusCode'] == 400 && result['body'].contains('server is unconfigured')) {
      return {
        'result': 'error',
        'message': 'server_not_configured',
        'log': AppLog(
          type: 'add_static_lease', 
          dateTime: DateTime.now(), 
          message: 'server_not_configured',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'add_static_lease', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future restoreAllLeases({
  required Server server,
}) async {
  final result = await apiRequest(
    urlPath: '/dhcp/reset_leases', 
    method: 'post',
    server: server, 
    body: {},
    type: 'restore_all_leases'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {'result': 'success'};
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'restore_all_leases', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getDnsRewriteRules({
  required Server server,
}) async {
  final result = await apiRequest(
    urlPath: '/rewrite/list', 
    method: 'get',
    server: server, 
    type: 'get_dns_rewrite_rules'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      final List<RewriteRulesData> data = List<RewriteRulesData>.from(
        jsonDecode(result['body']).map((item) => RewriteRulesData.fromJson(item))
      );

      return {
        'result': 'success',
        'data': data
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_dns_rewrite_rules', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future deleteDnsRewriteRule({
  required Server server,
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/rewrite/delete', 
    method: 'post',
    server: server, 
    body: data,
    type: 'delete_dns_rewrite_rule'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 'result': 'success' };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'delete_dns_rewrite_rule', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future addDnsRewriteRule({
  required Server server,
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/rewrite/add', 
    method: 'post',
    server: server, 
    body: data,
    type: 'add_dns_rewrite_rule'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 'result': 'success' };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'add_dns_rewrite_rule', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getQueryLogInfo({
  required Server server,
}) async {
  final result = await apiRequest(
    urlPath: '/querylog_info', 
    method: 'get',
    server: server, 
    type: 'get_query_log_info'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 
        'result': 'success', 
        'data': jsonDecode(result['body']) 
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_query_log_info', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future updateQueryLogParameters({
  required Server server,
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/querylog_config', 
    method: 'post',
    server: server, 
    body: data,
    type: 'update_query_log_config'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 'result': 'success' };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_query_log_config', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future clearLogs({
  required Server server,
}) async {
  final result = await apiRequest(
    urlPath: '/querylog_clear', 
    method: 'post',
    server: server, 
    body: {},
    type: 'clear_query_logs'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 'result': 'success' };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'clear_query_logs', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getDnsInfo({
  required Server server,
}) async {
  final result = await apiRequest(
    urlPath: '/dns_info', 
    method: 'get',
    server: server, 
    type: 'get_dns_info'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success' ,
        'data': DnsInfoData.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_dns_info', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future setDnsConfig({
  required Server server,
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/dns_config', 
    method: 'post',
    server: server,
    body: data, 
    type: 'set_dns_config'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 'result': 'success' };
    }
    if (result['statusCode'] == 400) {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'set_dns_config', 
          dateTime: DateTime.now(), 
          message: 'data_not_valid',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'set_dns_config', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future getEncryptionSettings({
  required Server server,
}) async {
  final result = await apiRequest(
    urlPath: '/tls/status', 
    method: 'get',
    server: server,
    type: 'get_encryption_settings'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 
        'result': 'success',
        'data': EncryptionData.fromJson(jsonDecode(result['body']))
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'get_encryption_settings', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future checkEncryptionSettings({
  required Server server,
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/tls/validate', 
    method: 'post',
    server: server,
    body: data,
    type: 'check_encryption_settings'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return {
        'result': 'success',
        'data': jsonDecode(result['body'])
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'check_encryption_settings', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future saveEncryptionSettings({
  required Server server,
  required Map<String, dynamic> data,
}) async {
  final result = await apiRequest(
    urlPath: '/tls/configure', 
    method: 'post',
    server: server,
    body: data,
    type: 'update_encryption_settings'
  );

  if (result['hasResponse'] == true) {
    if (result['statusCode'] == 200) {
      return { 'result': 'success' };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_encryption_settings', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: result['statusCode'].toString(),
          resBody: result['body'],
        )
      };
    }
  }
  else {
    return result;
  }
}

Future checkAppUpdatesGitHub() async {
  try {
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(Urls.checkLatestReleaseUrl));
    HttpClientResponse response = await request.close();
    String reply = await response.transform(utf8.decoder).join();
    httpClient.close();
    if (response.statusCode == 200) {
      return {
        'result': 'success',
        'hasResponse': true,
        'error': false,
        'statusCode': response.statusCode,
        'body': GitHubRelease.fromJson(jsonDecode(reply))
      };
    }
    else {
      return {
        'result': 'error',
        'log': AppLog(
          type: 'update_encryption_settings', 
          dateTime: DateTime.now(), 
          message: 'error_code_not_expected',
          statusCode: response.statusCode.toString(),
          resBody: reply,
        )
      };
    }    
  } on SocketException {
    return {
      'result': 'no_connection', 
      'message': 'SocketException',
      'log': AppLog(
        type: 'check_latest_release_github', 
        dateTime: DateTime.now(), 
        message: 'SocketException'
      )
    };
  } on TimeoutException {
    return {
      'result': 'no_connection', 
      'message': 'TimeoutException',
      'log': AppLog(
        type: 'check_latest_release_github', 
        dateTime: DateTime.now(), 
        message: 'TimeoutException'
      )
    };
  } on HandshakeException {
    return {
      'result': 'ssl_error', 
      'message': 'HandshakeException',
      'log': AppLog(
        type: 'check_latest_release_github', 
        dateTime: DateTime.now(), 
        message: 'HandshakeException'
      )
    };
  } catch (e) {
    return {
      'result': 'error', 
      'message': e.toString(),
      'log': AppLog(
        type: 'check_latest_release_github', 
        dateTime: DateTime.now(), 
        message: e.toString()
      )
    };
  } 
}