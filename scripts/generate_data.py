import psycopg2
import random
from datetime import datetime, timedelta
import os

# ==============================================
# КОНФИГУРАЦИЯ (заполни своими данными)
# ==============================================
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "your_host"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "database": os.getenv("DB_NAME", "your_database"),
    "user": os.getenv("DB_USER", "your_user"),
    "password": os.getenv("DB_PASSWORD", "your_password")
}

NUM_USERS = 5000
NUM_DRIVERS = 1000
START_DATE = datetime(2025, 1, 1)
END_DATE = datetime(2026, 4, 11)
NUM_DAYS = (END_DATE - START_DATE).days

CAR_BRANDS = {
    "Toyota": ["Camry", "Corolla", "Prius", "RAV4"],
    "Hyundai": ["Solaris", "Elantra", "Creta"],
    "Kia": ["Rio", "Cerato", "Sportage"],
    "Skoda": ["Octavia", "Rapid"],
    "Volkswagen": ["Polo", "Jetta", "Tiguan"],
    "Renault": ["Logan", "Sandero", "Duster"],
    "BMW": ["3 Series", "5 Series", "X3"],
    "Mercedes": ["C-Class", "E-Class", "GLC"],
    "Lada": ["Vesta", "Granta", "Largus"]
}

ORDER_TYPES = ["city", "intercity", "corporate", "delivery"]
ORDER_TYPE_WEIGHTS = [0.7, 0.15, 0.1, 0.05]
BASE_PRICE = {"city": 200, "intercity": 800, "corporate": 400, "delivery": 300}
MOSCOW_LAT = (55.5, 55.9)
MOSCOW_LON = (37.3, 37.8)

def generate_users():
    users = []
    for i in range(1, NUM_USERS + 1):
        rating = round(random.uniform(3.5, 5.0), 2)
        reg_date = START_DATE + timedelta(days=random.randint(0, NUM_DAYS))
        users.append((i, rating, reg_date))
    return users

def generate_drivers():
    drivers = []
    brands = list(CAR_BRANDS.keys())
    for i in range(1, NUM_DRIVERS + 1):
        rating = round(random.uniform(3.5, 5.0), 2)
        exp_days = random.randint(0, 365 * 3)
        car_brand = random.choice(brands)
        car_model = random.choice(CAR_BRANDS[car_brand])
        reg_date = START_DATE + timedelta(days=random.randint(0, NUM_DAYS))
        drivers.append((i, rating, exp_days, car_brand, car_model, reg_date))
    return drivers

def generate_orders_and_rides(users, drivers):
    orders = []
    rides = []
    order_id = 1
    
    for day in range(NUM_DAYS + 1):
        current_date = START_DATE + timedelta(days=day)
        orders_per_day = random.randint(300, 800)
        
        for _ in range(orders_per_day):
            user_id = random.randint(1, NUM_USERS)
            driver_id = random.randint(1, NUM_DRIVERS)
            order_type = random.choices(ORDER_TYPES, weights=ORDER_TYPE_WEIGHTS)[0]
            start_price = BASE_PRICE[order_type] + random.randint(-50, 150)
            hour = random.randint(6, 23)
            minute = random.randint(0, 59)
            created_at = current_date.replace(hour=hour, minute=minute)
            from_lat = round(random.uniform(*MOSCOW_LAT), 6)
            from_lon = round(random.uniform(*MOSCOW_LON), 6)
            to_lat = round(from_lat + random.uniform(-0.05, 0.05), 6)
            to_lon = round(from_lon + random.uniform(-0.05, 0.05), 6)
            
            orders.append((order_id, user_id, driver_id, order_type, start_price, created_at,
                          from_lat, from_lon, to_lat, to_lon))
            
            if random.random() < 0.9:
                ride_price = round(start_price * random.uniform(0.9, 1.3), 2)
                wait_minutes = random.randint(5, 20)
                ride_started_at = created_at + timedelta(minutes=wait_minutes)
                ride_duration = random.randint(15, 60)
                ride_ended_at = ride_started_at + timedelta(minutes=ride_duration)
                rides.append((order_id, ride_price, ride_started_at, ride_ended_at))
            
            order_id += 1
    
    return orders, rides

def insert_data(conn, users, drivers, orders, rides):
    cur = conn.cursor()
    
    print("Очистка таблиц...")
    cur.execute("TRUNCATE users, drivers, orders, rides RESTART IDENTITY CASCADE;")
    conn.commit()
    
    print("Вставка пользователей...")
    cur.executemany("INSERT INTO users (user_id, pass_rating, registered_at) VALUES (%s, %s, %s)", users)
    conn.commit()
    
    print("Вставка водителей...")
    cur.executemany("INSERT INTO drivers (driver_id, driver_rating, experience_days, car_brand, car_model, registered_at) VALUES (%s, %s, %s, %s, %s, %s)", drivers)
    conn.commit()
    
    print("Вставка заказов...")
    for i in range(0, len(orders), 10000):
        batch = orders[i:i+10000]
        cur.executemany("""
            INSERT INTO orders (order_id, user_id, driver_id, order_type, start_price, created_at,
                               from_lat, from_lon, to_lat, to_lon)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, batch)
        conn.commit()
        print(f"  → {min(i+10000, len(orders))}/{len(orders)} заказов")
    
    print("Вставка поездок...")
    for i in range(0, len(rides), 10000):
        batch = rides[i:i+10000]
        cur.executemany("""
            INSERT INTO rides (order_id, ride_price, ride_started_at, ride_ended_at)
            VALUES (%s, %s, %s, %s)
        """, batch)
        conn.commit()
        print(f"  → {min(i+10000, len(rides))}/{len(rides)} поездок")
    
    print("✅ ГОТОВО!")

def main():
    print("Генерация данных...")
    users = generate_users()
    drivers = generate_drivers()
    orders, rides = generate_orders_and_rides(users, drivers)
    
    print(f"Создано: {len(users)} пассажиров, {len(drivers)} водителей, {len(orders)} заказов, {len(rides)} поездок")
    
    print("Подключение к БД...")
    conn = psycopg2.connect(**DB_CONFIG)
    insert_data(conn, users, drivers, orders, rides)
    conn.close()
    print("🎉 Готово!")

if __name__ == "__main__":
    main()