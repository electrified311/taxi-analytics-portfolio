# 🚖 Аналитика такси-сервиса

Пет-проект по анализу данных такси-сервиса(на модифицированной базе Drivee) за 2025–2026 годы.

---

## 📌 Технологии

- Yandex Cloud (ВМ)
- PostgreSQL
- Redash
- Airflow
- Python (pandas, scipy, sqlalchemy)
- Git

---

## 🖥️ 1. Развёртывание инфраструктуры

Создана ВМ в Yandex Cloud (2 vCPU, 4 ГБ RAM, 20 ГБ SSD).  
Установлены PostgreSQL, Redash, Airflow.

![Yandex Cloud](screenshots/1.png)

---

## 🗄️ 2. База данных

Создана БД `taxi_analytics` с таблицами:

- `users` — пассажиры
- `drivers` — водители
- `orders` — заказы
- `rides` — поездки

![Схема БД](screenshots/1.png)
![Таблицы](screenshots/4.png)

---

## 🐍 3. Генерация данных

Написан Python-скрипт для заполнения БД:

- 5000 пассажиров
- 1000 водителей
- ~50 000 заказов
- ~45 000 поездок

[Скрипт](scripts/generate_data.py)

![Python скрипт](screenshots/5.png)
![Таблицы заполнены](screenshots/6.png)

---

## ⏰ 4. Автоматизация (Airflow)

Создан DAG `taxi_daily_etl`.  
Запуск каждый день в 00:00 UTC, добавляет 30–80 заказов и поездок за текущую дату.

[Код DAG](airflow/taxi_daily_etl.py)

![Airflow DAG](screenshots/7.png)
![Airflow успех](screenshots/8.png)

---

## 📊 5. Дашборды Redash

### 5.1 Итоги за 2025
Выручка, заказы, поездки, AOV, DAU, WAU, MAU, LTV, топ водителей, типы поездок, аналитика по маркам.

![Дашборд 2025](screenshots/9.png)

### 5.2 Итоги за 2026
Аналогичные метрики за январь–апрель 2026.

![Дашборд 2026](screenshots/10.png)

### 5.3 Оперативные метрики (LIVE)
Сравнение сегодня vs вчера (выручка, поездки, средний чек, конверсия).

![LIVE дашборд](screenshots/11.png)

### 5.4 Когортная матрица
Удержание пассажиров по месяцам (M0–M12).

![Cohort Matrix](screenshots/12.png)

---

## 🔬 6. Проверка гипотез

Jupyter Notebook, подключение к PostgreSQL через `create_engine`.  
Проверены 5 гипотез (t-test):

| № | Гипотеза | Результат |
|---|----------|-----------|
| 1 | Рейтинг >4.8 → выше выручка | ❌ |
| 2 | В выходные чек выше | ❌ |
| 3 | Конверсия city > intercity | ❌ |
| 4 | Опытные водители зарабатывают больше | ❌ |
| 5 | Вечерний чек > утреннего | ❌ |

[Ноутбук](notebooks/hypotheses_testing.ipynb)

![Результаты](screenshots/13.png)

---

## ✅ Итоги

- Развёрнута облачная инфраструктура
- Созданы 3 дашборда (14+ визуализаций)
- Настроена автоматизация через Airflow
- Проверены 5 статистических гипотез

---

## 🔗 Ссылки

- [Публичные дашборды Redash](http://111.88.152.24:5000)
- [GitHub репозиторий](https://github.com/твой_логин/taxi-analytics-portfolio)

---

## 📬 Контакты

- Telegram: @username
- Email: name@example.com