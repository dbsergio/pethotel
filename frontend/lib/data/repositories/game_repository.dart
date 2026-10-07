import '../../game/models/player.dart';

abstract class GameRepository {
  Future<Player?> loadPlayer(String playerId);
  Future<void> savePlayer(Player player);
  Future<void> syncPending();
}
