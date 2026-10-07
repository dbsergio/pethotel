package com.mypet.controller;

import com.mypet.document.GameSave;
import com.mypet.dto.SyncResponse;
import com.mypet.service.GameSaveService;
import com.mypet.security.CustomUserDetails;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/game")
public class GameController {

    private final GameSaveService gameSaveService;

    public GameController(GameSaveService gameSaveService) {
        this.gameSaveService = gameSaveService;
    }

    @GetMapping("/save/{playerId}")
    public ResponseEntity<GameSave> getSave(@PathVariable String playerId, @AuthenticationPrincipal CustomUserDetails userDetails) {
        if (!playerId.equals(userDetails.getPlayerId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        GameSave save = gameSaveService.getSave(playerId);
        if (save != null) {
            return ResponseEntity.ok(save);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/save")
    public ResponseEntity<SyncResponse> syncSave(@RequestBody GameSave save, @AuthenticationPrincipal CustomUserDetails userDetails) {
        if (save == null || !userDetails.getPlayerId().equals(save.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        // Ensure userId is strictly set from the authenticated user, not what the client sent
        save.setUserId(userDetails.getUserId());
        try {
            SyncResponse response = gameSaveService.syncSave(save);
            if ("CONFLICT".equals(response.getStatus())) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
            }
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
