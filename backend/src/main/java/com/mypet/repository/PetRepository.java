package com.mypet.repository;

import com.mypet.entity.Pet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PetRepository extends JpaRepository<Pet, String> {
    List<Pet> findByPlayerId(String playerId);
}
