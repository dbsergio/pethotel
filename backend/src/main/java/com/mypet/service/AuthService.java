package com.mypet.service;

import com.mypet.document.GameSave;
import com.mypet.document.User;
import com.mypet.dto.AuthRequest;
import com.mypet.dto.AuthResponse;
import com.mypet.repository.GameSaveRepository;
import com.mypet.repository.UserRepository;
import com.mypet.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final GameSaveRepository gameSaveRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(UserRepository userRepository, GameSaveRepository gameSaveRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.gameSaveRepository = gameSaveRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public AuthResponse register(AuthRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("El email ya está registrado");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        
        // If a playerId is passed from anonymous gameplay, associate it
        String playerId = request.getPlayerId();
        if (playerId == null || playerId.isEmpty()) {
            playerId = UUID.randomUUID().toString();
        }
        user.setPlayerId(playerId);
        
        user = userRepository.save(user);

        // Claim the existing save if there is one in DB for that playerId, and set the userId
        Optional<GameSave> existingSave = gameSaveRepository.findById(playerId);
        if (existingSave.isPresent()) {
            GameSave save = existingSave.get();
            save.setUserId(user.getId());
            save.setUpdatedAt(LocalDateTime.now());
            gameSaveRepository.save(save);
        }

        String token = jwtUtil.generateToken(user.getId(), user.getPlayerId());
        return new AuthResponse(token, user.getPlayerId(), user.getId());
    }

    public AuthResponse login(AuthRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Credenciales inválidas"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Credenciales inválidas");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getPlayerId());
        return new AuthResponse(token, user.getPlayerId(), user.getId());
    }
}
