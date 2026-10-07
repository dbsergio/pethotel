import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/local_game_repository.dart';
import '../repositories/remote_game_repository.dart';
import '../local/local_storage.dart';

enum SyncStatus { synced, pending, syncing, error, conflict }

class GameSyncService extends ChangeNotifier {
  final LocalGameRepository localRepo;
  final RemoteGameRepository remoteRepo;
  
  SyncStatus _status = SyncStatus.synced;
  SyncStatus get status => _status;
  
  Timer? _debounceTimer;

  GameSyncService({required this.localRepo, required this.remoteRepo}) {
    // Check initial state
    if (LocalStorage.prefs.getBool('sync_pending') == true) {
      _setStatus(SyncStatus.pending);
    }
  }

  void _setStatus(SyncStatus s) {
    if (_status != s) {
      _status = s;
      notifyListeners();
    }
  }

  void markPending() {
    _setStatus(SyncStatus.pending);
    _scheduleSync();
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      syncNow();
    });
  }

  Future<void> syncNow() async {
    if (_status == SyncStatus.syncing || _status == SyncStatus.conflict) return;
    
    _setStatus(SyncStatus.syncing);
    
    try {
      await localRepo.syncPending(); // Modificado para hacer post a MongoDB
      
      final conflict = LocalStorage.prefs.getBool('sync_conflict') ?? false;
      if (conflict) {
        _setStatus(SyncStatus.conflict);
      } else {
        final pending = LocalStorage.prefs.getBool('sync_pending') ?? false;
        if (pending) {
          _setStatus(SyncStatus.error); // Network error probably
        } else {
          _setStatus(SyncStatus.synced);
        }
      }
    } catch (e) {
      _setStatus(SyncStatus.error);
    }
  }

  void resolveConflict(bool useLocal) async {
    if (useLocal) {
      // If using local, we just bump the revision and try again to force overwrite
      // This logic will be triggered by GameState
    }
    
    LocalStorage.prefs.setBool('sync_conflict', false);
    LocalStorage.prefs.remove('conflict_data');
    _setStatus(SyncStatus.pending);
    syncNow();
  }
}
