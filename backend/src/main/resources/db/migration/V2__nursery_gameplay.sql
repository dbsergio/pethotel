-- Add nursery level to players
ALTER TABLE players ADD COLUMN nursery_level INT NOT NULL DEFAULT 1;

-- Clients table
CREATE TABLE clients (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Boardings table (estancias)
CREATE TABLE boardings (
    id VARCHAR(36) PRIMARY KEY,
    player_id VARCHAR(36) NOT NULL,
    client_id VARCHAR(36) NOT NULL,
    status VARCHAR(50) NOT NULL, -- 'ACTIVE', 'COMPLETED'
    reward INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- Modify pets to link to boardings instead of directly to players (for nursery pets)
-- Since we don't want to break V1 destructively, we can add boarding_id to pets.
ALTER TABLE pets ADD COLUMN boarding_id VARCHAR(36);
ALTER TABLE pets ADD CONSTRAINT fk_pet_boarding FOREIGN KEY (boarding_id) REFERENCES boardings(id) ON DELETE SET NULL;
