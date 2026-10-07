package com.mypet.dto;

public class BoardingDTO {
    private String id;
    private String clientId;
    private String petId;
    private String status;
    private Integer reward;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getClientId() { return clientId; }
    public void setClientId(String clientId) { this.clientId = clientId; }
    public String getPetId() { return petId; }
    public void setPetId(String petId) { this.petId = petId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Integer getReward() { return reward; }
    public void setReward(Integer reward) { this.reward = reward; }
}
