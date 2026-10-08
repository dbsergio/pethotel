import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/remote_game_repository.dart';
import '../../data/local/game_state.dart';
import '../../data/local/local_storage.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  final AuthRepository _authRepo = AuthRepository();
  final RemoteGameRepository _remoteRepo = RemoteGameRepository();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    final gs = context.read<GameState>();
    final currentId = gs.player?.id ?? LocalStorage.getPlayerId();

    final success = await _authRepo.register(_emailCtrl.text, _passCtrl.text, currentId);
    setState(() => _isLoading = false);
    
    if (success) {
      _showSnack('Cuenta creada. Tu partida está protegida.');
      gs.syncService.markPending(); // forces an immediate sync
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack('Error al registrar. Revisa los datos.');
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final success = await _authRepo.login(_emailCtrl.text, _passCtrl.text);
    if (success) {
      final newPlayerId = LocalStorage.getPlayerId();
      
      // Reload game state with the new (or downloaded) player.
      // GameState.loadPlayer will now handle fetching the remote save and merging.
      final gs = context.read<GameState>();
      await gs.loadPlayer(newPlayerId);
      
      _showSnack('Sesión iniciada. Partida restaurada.');
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _isLoading = false);
      _showSnack('Credenciales incorrectas o error de red.');
    }
  }

  void _logout() {
    _authRepo.logout();
    _showSnack('Sesión cerrada. Puedes seguir jugando localmente.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authRepo.isLoggedIn();

    if (isLoggedIn) {
      return AlertDialog(
        title: const Text('Mi Cuenta'),
        content: const Text('Ya tienes la sesión iniciada. Tu progreso se sincroniza con la nube.'),
        actions: [
          TextButton(onPressed: _logout, child: const Text('Cerrar Sesión')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Cuenta MYPET'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : _register, child: const Text('Crear Cuenta')),
        ElevatedButton(onPressed: _isLoading ? null : _login, child: const Text('Iniciar Sesión')),
      ],
    );
  }
}
