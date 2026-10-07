package com.mypet.dto;

import java.util.List;

public class SyncRequestDTO {
    private PlayerDTO player;
    private List<PetDTO> pets;
    private List<ClientDTO> clients;
    private List<BoardingDTO> boardings;

    public PlayerDTO getPlayer() { return player; }
    public void setPlayer(PlayerDTO player) { this.player = player; }
    public List<PetDTO> getPets() { return pets; }
    public void setPets(List<PetDTO> pets) { this.pets = pets; }
    public List<ClientDTO> getClients() { return clients; }
    public void setClients(List<ClientDTO> clients) { this.clients = clients; }
    public List<BoardingDTO> getBoardings() { return boardings; }
    public void setBoardings(List<BoardingDTO> boardings) { this.boardings = boardings; }
}
