package com.mypet.dto;

public class PetDTO {
    private String id;
    private String name;
    private String species;
    private PetStatsDTO stats;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSpecies() { return species; }
    public void setSpecies(String species) { this.species = species; }
    public PetStatsDTO getStats() { return stats; }
    public void setStats(PetStatsDTO stats) { this.stats = stats; }
}
