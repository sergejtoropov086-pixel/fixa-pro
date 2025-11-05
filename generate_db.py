import sqlite3
import random

brands = ["Bosch", "Indesit", "Atlant", "Samsung", "LG", "Whirlpool", "Electrolux", "Ariston", "Candy", "Zanussi", "Midea", "Haier", "Gorenje", "Beko", "Toshiba"]
types = ["Стиральная машина", "Холодильник", "Духовой шкаф", "Посудомоечная машина", "Вытяжка", "Сушильная машина"]
statuses = ["В наличии", "Ожидается", "Куплено"]

prefixes = {
    "Стиральная машина": ["WAT", "IWC", "WS", "WW", "F", "EWF", "LDF", "FWD"],
    "Холодильник": ["KGN", "DF", "RB", "GN", "C", "RF", "GR", "NR"],
    "Духовой шкаф": ["HBG", "EOF", "FO", "BO", "HBA", "BOP", "OEF"],
    "Посудомоечная машина": ["SMS", "LDF", "DW", "ZDF", "LSF", "DFE"],
    "Вытяжка": ["DHF", "CFM", "HFC", "ZV", "TL", "CH"],
    "Сушильная машина": ["WT", "TD", "DV", "EDV", "TDC", "WTE"]
}

conn = sqlite3.connect('appliances.db')
cursor = conn.cursor()

cursor.execute('''
    CREATE TABLE appliances (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        type TEXT NOT NULL,
        part_status TEXT NOT NULL
    )
''')

cursor.execute('''
    CREATE TABLE user_appliances (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        type TEXT,
        part_status TEXT,
        photo_path TEXT
    )
''')

# Генерация 3 000 000 записей
batch = []
for i in range(1, 3_000_001):
    t = random.choice(types)
    brand = random.choice(brands)
    prefix = random.choice(prefixes[t])
    model = f"{brand} {prefix}{random.randint(1000, 99999)}"
    status = random.choice(statuses)
    batch.append((i, model, brand, t, status))
    
    if len(batch) >= 10000:  # пакетная вставка
        cursor.executemany('INSERT INTO appliances VALUES (?, ?, ?, ?, ?)', batch)
        batch = []
        print(f"Записано: {i} / 3 000 000")

# Остаток
if batch:
    cursor.executemany('INSERT INTO appliances VALUES (?, ?, ?, ?, ?)', batch)

conn.commit()
conn.close()
print("✅ База appliances.db готова (3 млн записей)")
