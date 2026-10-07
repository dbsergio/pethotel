package com.mypet.dto;

public class AuthResponse {
    private String token;
    private String playerId;
    private String userId;

    public AuthResponse(String token, String playerId, String userId) {
        this.token = token;
        this.playerId = playerId;
        this.userId = userId;
    }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    public String getPlayerId() { return playerId; }
    public void setPlayerId(String playerId) { this.playerId = playerId; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
}
