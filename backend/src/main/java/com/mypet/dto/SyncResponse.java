package com.mypet.dto;

import com.mypet.document.GameSave;

public class SyncResponse {
    private String status; // "OK", "CONFLICT"
    private GameSave serverSave;

    public SyncResponse(String status, GameSave serverSave) {
        this.status = status;
        this.serverSave = serverSave;
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public GameSave getServerSave() { return serverSave; }
    public void setServerSave(GameSave serverSave) { this.serverSave = serverSave; }
}
