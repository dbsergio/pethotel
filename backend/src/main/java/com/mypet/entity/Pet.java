package com.mypet.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;
import java.time.LocalDateTime;

@Entity
@Table(name = "pets")
public class Pet {

    @Id
    private String id;

    @ManyToOne
    @JoinColumn(name = "player_id", nullable = true) // Can be true if we rely on boarding
    private Player player;

    @ManyToOne
    @JoinColumn(name = "boarding_id", nullable = true)
    private Boarding boarding;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String species;

    private String personality;

    @Column(nullable = false)
    private Double hunger = 100.0;

    @Column(nullable = false)
    private Double thirst = 100.0;

    @Column(nullable = false)
    private Double happiness = 100.0;

    @Column(nullable = false)
    private Double hygiene = 100.0;

    @Column(nullable = false)
    private Double energy = 100.0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public Player getPlayer() { return player; }
    public void setPlayer(Player player) { this.player = player; }
    public Boarding getBoarding() { return boarding; }
    public void setBoarding(Boarding boarding) { this.boarding = boarding; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSpecies() { return species; }
    public void setSpecies(String species) { this.species = species; }
    public String getPersonality() { return personality; }
    public void setPersonality(String personality) { this.personality = personality; }
    public Double getHunger() { return hunger; }
    public void setHunger(Double hunger) { this.hunger = hunger; }
    public Double getThirst() { return thirst; }
    public void setThirst(Double thirst) { this.thirst = thirst; }
    public Double getHappiness() { return happiness; }
    public void setHappiness(Double happiness) { this.happiness = happiness; }
    public Double getHygiene() { return hygiene; }
    public void setHygiene(Double hygiene) { this.hygiene = hygiene; }
    public Double getEnergy() { return energy; }
    public void setEnergy(Double energy) { this.energy = energy; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
