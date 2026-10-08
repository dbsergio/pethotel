import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypet_frontend/data/local/local_storage.dart';
import 'package:mypet_frontend/data/repositories/local_game_repository.dart';
import 'package:mypet_frontend/data/repositories/remote_game_repository.dart';
import 'package:mypet_frontend/data/services/game_sync_service.dart';

class MockLocalRepo extends LocalGameRepository {
  int syncCalls = 0;
  
  @override
  Future<void> syncPending() async {
    syncCalls++;
    // Simulate a 409 Conflict response by setting the shared prefs flags
    await LocalStorage.prefs.setBool('sync_conflict', true);
    await LocalStorage.prefs.setString('conflict_data', '{"status":"CONFLICT"}');
  }
}

class MockRemoteRepo extends RemoteGameRepository {}

void main() {
  test('markPending should not overwrite conflict status and cause 409 loop', () async {
    SharedPreferences.setMockInitialValues({
      'sync_pending': false,
    });
    await LocalStorage.init();

    final localRepo = MockLocalRepo();
    final remoteRepo = MockRemoteRepo();
    final syncService = GameSyncService(localRepo: localRepo, remoteRepo: remoteRepo);

    // 1. Trigger the first action which starts the sync process
    syncService.markPending();
    
    // Simulate the timer firing
    await syncService.syncNow();
    
    // It should have called syncPending once, which simulated a 409 Conflict
    expect(localRepo.syncCalls, 1);
    expect(syncService.status, SyncStatus.conflict);

    // 2. Trigger another action while in conflict state
    // In the old buggy code, markPending() would overwrite SyncStatus.conflict to SyncStatus.pending
    syncService.markPending();
    
    // Verify that the status remains conflict (thanks to our fix!)
    expect(syncService.status, SyncStatus.conflict);
    
    // If we call syncNow() again (as the timer would do), it should early-return and NOT call syncPending
    await syncService.syncNow();
    expect(localRepo.syncCalls, 1); // Still 1! The infinite loop is prevented.
  });
}
