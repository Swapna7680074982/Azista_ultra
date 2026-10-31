import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../utilities/mylogger.dart';

class OfflineSyncService {
  static const String _pendingPobKey = "offline_pending_pobs";
  static const String _pendingPosKey = "offline_pending_pos";

  static Future<void> savePendingPob(Map<String, dynamic> pobData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingPobKey) ?? [];
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      pobData['offline_id'] = id;
      pobData['created_at'] = DateTime.now().toIso8601String();
      list.add(jsonEncode(pobData));
      await prefs.setStringList(_pendingPobKey, list);
      AppLogger.info("Saved pending POB offline: $id");
    } catch (e) {
      AppLogger.error("Failed to save pending POB offline", e);
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingPobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingPobKey) ?? [];
      return list.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.error("Failed to get pending POBs", e);
      return [];
    }
  }

  static Future<void> clearPendingPobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingPobKey);
    } catch (e) {
      AppLogger.error("Failed to clear pending POBs", e);
    }
  }

  static Future<void> savePendingPos(Map<String, dynamic> posData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingPosKey) ?? [];
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      posData['offline_id'] = id;
      posData['created_at'] = DateTime.now().toIso8601String();
      list.add(jsonEncode(posData));
      await prefs.setStringList(_pendingPosKey, list);
      AppLogger.info("Saved pending POS offline: $id");
    } catch (e) {
      AppLogger.error("Failed to save pending POS offline", e);
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingPos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingPosKey) ?? [];
      return list.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.error("Failed to get pending POS", e);
      return [];
    }
  }

  static Future<void> clearPendingPos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingPosKey);
    } catch (e) {
      AppLogger.error("Failed to clear pending POS", e);
    }
  }

  static Future<void> clearAllPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingPobKey);
      await prefs.remove(_pendingPosKey);
    } catch (e) {
      AppLogger.error("Failed to clear all pending records", e);
    }
  }

  static Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pobs = prefs.getStringList(_pendingPobKey)?.length ?? 0;
      final pos = prefs.getStringList(_pendingPosKey)?.length ?? 0;
      return pobs + pos;
    } catch (_) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> syncAll({BuildContext? context}) async {
    int syncedPobs = 0;
    int syncedPos = 0;
    int failedCount = 0;
    String? lastErrorMsg;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Sync Pending POBs
      final pobStrings = prefs.getStringList(_pendingPobKey) ?? [];
      final remainingPobs = <String>[];

      for (var pobStr in pobStrings) {
        try {
          final pobMap = jsonDecode(pobStr) as Map<String, dynamic>;
          String? distId = pobMap['distributor_id']?.toString();
          if (distId == 'null' || distId == '') distId = null;

          File? imageFile;
          final imgPath = pobMap['image_path']?.toString();
          if (imgPath != null && imgPath.isNotEmpty) {
            final f = File(imgPath);
            if (f.existsSync()) {
              imageFile = f;
            }
          }

          final itemsJson = pobMap['items_json'] is List
              ? jsonEncode(pobMap['items_json'])
              : (pobMap['items_json']?.toString() ?? '[]');

          final response = await ApiServices.generatePob(
            outletId: pobMap['outlet_id']?.toString() ?? '',
            distributorId: distId,
            itemsJson: itemsJson,
            remarks: pobMap['remarks']?.toString() ?? '',
            orderCopy: imageFile,
          );

          if (response != null && ApiServices.isSuccess(response)) {
            syncedPobs++;
          } else if (response != null && response['status'] == false) {
            final serverMsg = response['message']?.toString() ?? "Server rejected POB";
            lastErrorMsg = serverMsg;
            // If already exists or duplicate on server, treat as uploaded/resolved
            if (serverMsg.toLowerCase().contains("already") || 
                serverMsg.toLowerCase().contains("duplicate") || 
                serverMsg.toLowerCase().contains("exist")) {
              syncedPobs++;
            } else {
              remainingPobs.add(pobStr);
              failedCount++;
            }
          } else {
            remainingPobs.add(pobStr);
            failedCount++;
            if (response != null && response['message'] != null) {
              lastErrorMsg = response['message'].toString();
            }
          }
        } catch (e) {
          remainingPobs.add(pobStr);
          failedCount++;
          lastErrorMsg = e.toString();
        }
      }
      await prefs.setStringList(_pendingPobKey, remainingPobs);

      // 2. Sync Pending POS transactions
      final posStrings = prefs.getStringList(_pendingPosKey) ?? [];
      final remainingPos = <String>[];

      for (var posStr in posStrings) {
        try {
          final posMap = jsonDecode(posStr) as Map<String, dynamic>;
          final payload = posMap['payload'] as Map<String, dynamic>? ?? {};
          final response = await ApiServices.submitPosTransaction(payload: payload);

          if (response != null && ApiServices.isSuccess(response)) {
            syncedPos++;
          } else if (response != null && response['status'] == false) {
            final serverMsg = response['message']?.toString() ?? "Server rejected transaction";
            lastErrorMsg = serverMsg;
            if (serverMsg.toLowerCase().contains("already") || 
                serverMsg.toLowerCase().contains("duplicate") || 
                serverMsg.toLowerCase().contains("exist")) {
              syncedPos++;
            } else {
              remainingPos.add(posStr);
              failedCount++;
            }
          } else {
            remainingPos.add(posStr);
            failedCount++;
            if (response != null && response['message'] != null) {
              lastErrorMsg = response['message'].toString();
            }
          }
        } catch (e) {
          remainingPos.add(posStr);
          failedCount++;
          lastErrorMsg = e.toString();
        }
      }
      await prefs.setStringList(_pendingPosKey, remainingPos);

      final totalSynced = syncedPobs + syncedPos;
      String message;
      if (totalSynced > 0 && failedCount == 0) {
        message = "Sync successful! $totalSynced offline records uploaded.";
      } else if (totalSynced > 0 && failedCount > 0) {
        message = "Synced $totalSynced records. $failedCount records pending: ${lastErrorMsg ?? 'check network'}.";
      } else if (failedCount > 0) {
        message = lastErrorMsg != null 
            ? "Sync failed: $lastErrorMsg"
            : "Sync failed for $failedCount records. Please check connection.";
      } else {
        message = "All data is already in sync with server.";
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
            action: failedCount > 0 
                ? SnackBarAction(
                    label: "DISCARD",
                    textColor: Colors.yellowAccent,
                    onPressed: () async {
                      await clearAllPending();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Pending records cleared.")),
                        );
                      }
                    },
                  )
                : null,
            backgroundColor: failedCount > 0 && totalSynced == 0 ? Colors.red.shade700 : Colors.green.shade700,
          ),
        );
      }

      return {
        "success": failedCount == 0,
        "syncedPobs": syncedPobs,
        "syncedPos": syncedPos,
        "failedCount": failedCount,
        "message": message,
        "lastErrorMsg": lastErrorMsg,
      };
    } catch (e) {
      AppLogger.error("SyncAll error", e);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync failed: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return {
        "success": false,
        "syncedPobs": syncedPobs,
        "syncedPos": syncedPos,
        "failedCount": failedCount,
        "message": "Sync error: $e",
      };
    }
  }
}
