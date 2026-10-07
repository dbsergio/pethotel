package com.mypet.service;

import com.mypet.dto.*;
import com.mypet.entity.*;
import com.mypet.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
import java.time.LocalDateTime;

@Service
public class GameSyncService {

    private final PlayerRepository playerRepository;
    private final PetRepository petRepository;
    private final ClientRepository clientRepository;
    private final BoardingRepository boardingRepository;

    public GameSyncService(PlayerRepository playerRepository, PetRepository petRepository, ClientRepository clientRepository, BoardingRepository boardingRepository) {
        this.playerRepository = playerRepository;
        this.petRepository = petRepository;
        this.clientRepository = clientRepository;
        this.boardingRepository = boardingRepository;
    }

    @Transactional
    public void syncGame(SyncRequestDTO syncData) {
        if (syncData.getPlayer() == null) return;
        
        String playerUuid = syncData.getPlayer().getId();
        
        Player player = playerRepository.findByPlayerUuid(playerUuid).orElseGet(() -> {
            Player newPlayer = new Player();
            newPlayer.setId(UUID.randomUUID().toString());
            newPlayer.setPlayerUuid(playerUuid);
            return newPlayer;
        });
        
        player.setCoins(syncData.getPlayer().getCoins());
        if (syncData.getPlayer().getNurseryLevel() != null) {
            player.setNurseryLevel(syncData.getPlayer().getNurseryLevel());
        }
        player.setUpdatedAt(LocalDateTime.now());
        player = playerRepository.save(player);

        if (syncData.getClients() != null) {
            for (ClientDTO c : syncData.getClients()) {
                Client client = clientRepository.findById(c.getId()).orElse(new Client());
                client.setId(c.getId());
                client.setName(c.getName());
                clientRepository.save(client);
            }
        }

        if (syncData.getBoardings() != null) {
            for (BoardingDTO b : syncData.getBoardings()) {
                Boarding boarding = boardingRepository.findById(b.getId()).orElse(new Boarding());
                boarding.setId(b.getId());
                boarding.setPlayer(player);
                clientRepository.findById(b.getClientId()).ifPresent(boarding::setClient);
                boarding.setStatus(b.getStatus());
                boarding.setReward(b.getReward());
                boardingRepository.save(boarding);
            }
        }
        
        if (syncData.getPets() != null) {
            for (PetDTO p : syncData.getPets()) {
                Pet pet = petRepository.findById(p.getId()).orElse(new Pet());
                pet.setId(p.getId());
                pet.setName(p.getName());
                pet.setSpecies(p.getSpecies());
                // For legacy compatibility or if the pet belongs directly to player
                pet.setPlayer(player);
                
                if (syncData.getBoardings() != null) {
                   // In a real app we'd map boarding_id in DTO, but we'll leave it for now or assume they are nursery pets
                }

                if (p.getStats() != null) {
                    pet.setHunger(p.getStats().getHunger());
                    pet.setThirst(p.getStats().getThirst());
                    pet.setHygiene(p.getStats().getHygiene());
                    pet.setEnergy(p.getStats().getEnergy());
                    pet.setHappiness(p.getStats().getHappiness());
                }
                pet.setUpdatedAt(LocalDateTime.now());
                petRepository.save(pet);
            }
        }
    }
}
