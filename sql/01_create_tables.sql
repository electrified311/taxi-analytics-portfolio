-- ==============================================
-- Таблица: users (пассажиры)
-- ==============================================
CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    pass_rating DECIMAL(3,2) DEFAULT 4.5,
    registered_at DATE
);

-- ==============================================
-- Таблица: drivers (водители)
-- ==============================================
CREATE TABLE drivers (
    driver_id BIGSERIAL PRIMARY KEY,
    driver_rating DECIMAL(3,2) DEFAULT 4.5,
    experience_days INT DEFAULT 0,
    car_brand VARCHAR(50),
    car_model VARCHAR(50),
    registered_at DATE
);

-- ==============================================
-- Таблица: orders (заказы)
-- ==============================================
CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    driver_id BIGINT REFERENCES drivers(driver_id),
    order_type VARCHAR(20) DEFAULT 'city',
    start_price DECIMAL(10,2),
    created_at TIMESTAMP,
    from_lat DECIMAL(10,7),
    from_lon DECIMAL(10,7),
    to_lat DECIMAL(10,7),
    to_lon DECIMAL(10,7)
);

-- ==============================================
-- Таблица: rides (поездки)
-- ==============================================
CREATE TABLE rides (
    ride_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT UNIQUE REFERENCES orders(order_id),
    ride_price DECIMAL(10,2),
    ride_started_at TIMESTAMP,
    ride_ended_at TIMESTAMP
);