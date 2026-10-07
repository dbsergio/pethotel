package com.mypet.security;

public class CustomUserDetails {
    private final String userId;
    private final String playerId;

    public CustomUserDetails(String userId, String playerId) {
        this.userId = userId;
        this.playerId = playerId;
    }

    public String getUserId() { return userId; }
    public String getPlayerId() { return playerId; }
}
