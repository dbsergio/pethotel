package com.mypet.controller;

import com.mypet.dto.SyncRequestDTO;
import com.mypet.service.GameSyncService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/game")
public class GameController {

    private final GameSyncService gameSyncService;

    public GameController(GameSyncService gameSyncService) {
        this.gameSyncService = gameSyncService;
    }

    @PostMapping("/sync")
    public ResponseEntity<Void> syncGame(@RequestBody SyncRequestDTO syncRequest) {
        gameSyncService.syncGame(syncRequest);
        return ResponseEntity.ok().build();
    }
}
