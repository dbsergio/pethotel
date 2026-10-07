package com.mypet.document;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Document(collection = "game_saves")
public class GameSave {
    @Id
    private String id; // This maps to "id" field in frontend Player JSON (playerId)
    private String userId; // Optional, links to registered User account
    private int saveVersion = 1;
    private int revision = 1;
    private int coins = 100;
    private int nurseryLevel = 1;
    private int capacity = 2;
    private List<Map<String, Object>> activePets = new ArrayList<>();
    private List<Map<String, Object>> activeStays = new ArrayList<>();
    private List<Map<String, Object>> completedStays = new ArrayList<>();
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public int getSaveVersion() { return saveVersion; }
    public void setSaveVersion(int saveVersion) { this.saveVersion = saveVersion; }
    public int getRevision() { return revision; }
    public void setRevision(int revision) { this.revision = revision; }
    public int getCoins() { return coins; }
    public void setCoins(int coins) { this.coins = coins; }
    public int getNurseryLevel() { return nurseryLevel; }
    public void setNurseryLevel(int nurseryLevel) { this.nurseryLevel = nurseryLevel; }
    public int getCapacity() { return capacity; }
    public void setCapacity(int capacity) { this.capacity = capacity; }
    public List<Map<String, Object>> getActivePets() { return activePets; }
    public void setActivePets(List<Map<String, Object>> activePets) { this.activePets = activePets; }
    public List<Map<String, Object>> getActiveStays() { return activeStays; }
    public void setActiveStays(List<Map<String, Object>> activeStays) { this.activeStays = activeStays; }
    public List<Map<String, Object>> getCompletedStays() { return completedStays; }
    public void setCompletedStays(List<Map<String, Object>> completedStays) { this.completedStays = completedStays; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
