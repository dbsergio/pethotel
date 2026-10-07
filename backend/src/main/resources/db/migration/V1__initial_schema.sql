CREATE TABLE players (
    id VARCHAR(36) PRIMARY KEY,
    player_uuid VARCHAR(36) UNIQUE NOT NULL,
    coins INT NOT NULL DEFAULT 100,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pets (
    id VARCHAR(36) PRIMARY KEY,
    player_id VARCHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    species VARCHAR(50) NOT NULL,
    personality VARCHAR(50),
    hunger FLOAT NOT NULL DEFAULT 100.0,
    thirst FLOAT NOT NULL DEFAULT 100.0,
    happiness FLOAT NOT NULL DEFAULT 100.0,
    hygiene FLOAT NOT NULL DEFAULT 100.0,
    energy FLOAT NOT NULL DEFAULT 100.0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE TABLE items (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    price INT NOT NULL,
    effect_type VARCHAR(50),
    effect_value FLOAT
);

CREATE TABLE inventories (
    id VARCHAR(36) PRIMARY KEY,
    player_id VARCHAR(36) NOT NULL UNIQUE,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE TABLE inventory_items (
    inventory_id VARCHAR(36) NOT NULL,
    item_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (inventory_id, item_id),
    FOREIGN KEY (inventory_id) REFERENCES inventories(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- Seed items
INSERT INTO items (id, name, description, category, price, effect_type, effect_value) VALUES
('food_premium', 'Comida Premium', 'Llena mucha hambre y da felicidad', 'food', 20, 'hunger', 40),
('food_normal', 'Comida Normal', 'Llena el hambre básica', 'food', 10, 'hunger', 25),
('water', 'Agua Fresca', 'Quita la sed', 'drink', 5, 'thirst', 30),
('ball', 'Pelota Roja', 'Una pelota saltarina', 'toy', 50, 'happiness', 15),
('soap', 'Jabón de Burbujas', 'Deja a tu mascota impecable', 'cleaning', 15, 'hygiene', 50);
