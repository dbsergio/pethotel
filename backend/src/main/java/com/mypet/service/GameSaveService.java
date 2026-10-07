package com.mypet.service;

import com.mypet.document.GameSave;
import com.mypet.dto.SyncResponse;
import com.mypet.repository.GameSaveRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class GameSaveService {

    private final GameSaveRepository gameSaveRepository;

    public GameSaveService(GameSaveRepository gameSaveRepository) {
        this.gameSaveRepository = gameSaveRepository;
    }

    public GameSave getSave(String playerId) {
        return gameSaveRepository.findById(playerId).orElse(null);
    }

    public SyncResponse syncSave(GameSave incomingSave) {
        if (incomingSave == null || incomingSave.getId() == null) {
            throw new IllegalArgumentException("Save debe tener un ID (playerId)");
        }
        
        Optional<GameSave> optionalCurrent = gameSaveRepository.findById(incomingSave.getId());
        
        if (optionalCurrent.isPresent()) {
            GameSave currentSave = optionalCurrent.get();
            // Optimistic Concurrency Check as requested:
            // Client sends expectedRevision. Server checks if it exactly matches current DB revision.
            if (incomingSave.getRevision() != currentSave.getRevision()) {
                // Conflict
                return new SyncResponse("CONFLICT", currentSave);
            }
        }
        
        // Increment the revision since it matched (or it's the first save)
        incomingSave.setRevision(incomingSave.getRevision() + 1);
        
        // Save the incoming document
        incomingSave.setUpdatedAt(LocalDateTime.now());
        if (incomingSave.getCreatedAt() == null) {
            incomingSave.setCreatedAt(LocalDateTime.now());
        }
        
        GameSave saved = gameSaveRepository.save(incomingSave);
        return new SyncResponse("OK", saved);
    }
}
