package com.mypet.repository;

import com.mypet.document.GameSave;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.Optional;

public interface GameSaveRepository extends MongoRepository<GameSave, String> {
    Optional<GameSave> findByUserId(String userId);
}
