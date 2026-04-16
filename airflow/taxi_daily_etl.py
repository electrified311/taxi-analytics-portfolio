from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import psycopg2
import random
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

ORDER_TYPES = ["city", "intercity", "corporate", "delivery"]
ORDER_TYPE_WEIGHTS = [0.7, 0.15, 0.1, 0.05]
BASE_PRICE = {"city": 200, "intercity": 800, "corporate": 400, "delivery": 300}
MOSCOW_LAT = (55.5, 55.9)
MOSCOW_LON = (37.3, 37.8)

def generate_daily_data(**context):
    # Берём текущую дату (СЕГОДНЯ)
    target_date = datetime.now().date().strftime('%Y-%m-%d')
    year, month, day = map(int, target_date.split('-'))
    target_datetime = datetime(year, month, day)
    
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    cur.execute("SELECT COUNT(*) FROM users")
    num_users = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM drivers")
    num_drivers = cur.fetchone()[0]
    
    cur.execute("SELECT COALESCE(MAX(order_id), 0) FROM orders")
    order_id = cur.fetchone()[0] + 1
    
    orders_count = random.randint(30, 80)
    orders_data = []
    rides_data = []
    
    for i in range(orders_count):
        user_id = random.randint(1, num_users)
        driver_id = random.randint(1, num_drivers)
        order_type = random.choices(ORDER_TYPES, weights=ORDER_TYPE_WEIGHTS)[0]
        start_price = BASE_PRICE[order_type] + random.randint(-50, 150)
        hour = random.randint(6, 23)
        minute = random.randint(0, 59)
        created_at = target_datetime.replace(hour=hour, minute=minute)
        from_lat = round(random.uniform(*MOSCOW_LAT), 6)
        from_lon = round(random.uniform(*MOSCOW_LON), 6)
        to_lat = round(from_lat + random.uniform(-0.05, 0.05), 6)
        to_lon = round(from_lon + random.uniform(-0.05, 0.05), 6)
        
        orders_data.append((order_id, user_id, driver_id, order_type, start_price, created_at,
                           from_lat, from_lon, to_lat, to_lon))
        
        if random.random() < 0.9:
            ride_price = round(start_price * random.uniform(0.9, 1.3), 2)
            wait_minutes = random.randint(5, 20)
            ride_started_at = created_at + timedelta(minutes=wait_minutes)
            ride_duration = random.randint(15, 60)
            ride_ended_at = ride_started_at + timedelta(minutes=ride_duration)
            rides_data.append((order_id, ride_price, ride_started_at, ride_ended_at))
        
        order_id += 1
    
    cur.executemany("""
        INSERT INTO orders (order_id, user_id, driver_id, order_type, start_price, created_at,
                           from_lat, from_lon, to_lat, to_lon)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, orders_data)
    
    if rides_data:
        cur.executemany("""
            INSERT INTO rides (order_id, ride_price, ride_started_at, ride_ended_at)
            VALUES (%s, %s, %s, %s)
        """, rides_data)
    
    conn.commit()
    cur.close()
    conn.close()
    
    print(f"✅ Добавлено {len(orders_data)} заказов и {len(rides_data)} поездок за {target_date}")

default_args = {
    'owner': 'analyst',
    'depends_on_past': False,
    'start_date': datetime(2026, 4, 12),
    'retries': 1,
}

dag = DAG(
    'taxi_daily_etl',
    default_args=default_args,
    description='Ежедневное добавление заказов и поездок',
    schedule_interval='0 0 * * *',
    catchup=False,
)

generate_task = PythonOperator(
    task_id='generate_daily_data',
    python_callable=generate_daily_data,
    dag=dag,
)