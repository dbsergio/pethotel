package com.mypet.repository;

import com.mypet.entity.Boarding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoardingRepository extends JpaRepository<Boarding, String> {
    List<Boarding> findByPlayerId(String playerId);
}
