import pandas as pd
import random
from faker import Faker
from datetime import timedelta

# Initialize Faker
fake = Faker()

# Step 1: Define hyper-realistic rules
financial_config = {
    "Income": {
        "Salary": {"range": (2500.00, 8500.00), "merchants": ["Google LLC", "Deloitte Consulting", "Amazon Corporate", "Meta Platforms", "HealthCare Corp"]},
        "Freelance": {"range": (150.00, 1800.00), "merchants": ["Upwork Escrow", "Fiverr International", "Strikingly Media", "Consulting Stipend"]},
        "Dividends": {"range": (15.00, 450.00), "merchants": ["Vanguard Clearing", "Charles Schwab Div", "Fidelity Brokerage"]},
        "Interest": {"range": (1.50, 65.00), "merchants": ["Ally Bank Interest", "Marcus by Goldman Sachs", "Capital One High-Yield"]},
        "Tax Refund": {"range": (400.00, 2800.00), "merchants": ["IRS Tax Refund", "State Dept of Revenue"]}
    },
    "Housing": {
        "Rent": {"range": (1100.00, 3100.00), "merchants": ["Avalon Communities", "Equity Residential", "Greystar Management", "Private Landlord Zelle"]},
        "Mortgage": {"range": (1400.00, 4200.00), "merchants": ["Chase Mortgage", "Wells Fargo Home Loans", "Rocket Mortgage LLC", "Bank of America Home"]},
        "Property Tax": {"range": (300.00, 1200.00), "merchants": ["County Tax Collector", "City Treasurer Office"]},
        "Home Maintenance": {"range": (45.00, 750.00), "merchants": ["The Home Depot", "Lowe's Home Improvement", "Ace Hardware", "Local Plumbing Services"]}
    },
    "Utilities": {
        "Electricity": {"range": (55.00, 280.00), "merchants": ["Duke Energy", "PG&E Corp", "Consolidated Edison", "Florida Power & Light"]},
        "Water": {"range": (25.00, 95.00), "merchants": ["City Water District", "Municipal Utilities Board"]},
        "Internet": {"range": (49.99, 120.00), "merchants": ["Comcast Xfinity", "AT&T Internet", "Verizon Fios", "Spectrum Broadband"]},
        "Gas": {"range": (30.00, 140.00), "merchants": ["National Grid", "SoCalGas", "CenterPoint Energy"]},
        "Trash": {"range": (15.00, 45.00), "merchants": ["Waste Management Inc.", "Republic Services"]}
    },
    "Transportation": {
        "Fuel": {"range": (25.00, 85.00), "merchants": ["Shell Oil", "Chevron", "ExxonMobil", "BP Amoco", "7-Eleven Fuel"]},
        "Public Transit": {"range": (2.75, 45.00), "merchants": ["MTA Subway/Bus", "CTA Transit", "Amtrak Train Tickets", "London Underground"]},
        "Auto Maintenance": {"range": (60.00, 850.00), "merchants": ["Jiffy Lube", "Firestone Complete Auto", "AutoZone", "Local Dealership Service"]},
        "Parking": {"range": (5.00, 40.00), "merchants": ["SP+ Parking", "ParkWhiz", "City Parking Meter"]},
        "Rideshare": {"range": (8.50, 55.00), "merchants": ["Uber Trip", "Lyft Ride"]}
    },
    "Entertainment": {
        "Movies": {"range": (12.00, 45.00), "merchants": ["AMC Theatres", "Regal Cinemas", "Fandango"]},
        "Subscriptions": {"range": (6.99, 22.99), "merchants": ["Netflix Inc.", "Spotify Premium", "Disney+", "Hulu LLC", "Amazon Prime Video"]},
        "Concerts": {"range": (75.00, 450.00), "merchants": ["Ticketmaster", "Live Nation", "StubHub Inc."]},
        "Gaming": {"range": (4.99, 69.99), "merchants": ["PlayStation Network", "Steam Games", "Xbox Live", "Nintendo eShop", "Epic Games Store"]}
    },
    "Shopping": {
        "Clothing": {"range": (20.00, 250.00), "merchants": ["H&M", "Zara", "Nike Store", "Nordstrom", "Macy's", "TJ Maxx"]},
        "Electronics": {"range": (45.00, 1499.00), "merchants": ["Apple Store", "Best Buy", "Amazon.com Electronics"]},
        "Sporting Goods": {"range": (15.00, 180.00), "merchants": ["Dick's Sporting Goods", "REI Co-op", "Academy Sports"]},
        "Books": {"range": (9.99, 45.00), "merchants": ["Barnes & Noble", "Amazon Books", "Local Independent Bookstore"]}
    }
}

account_tiers = ["Basic Checking", "Premium Checking", "Business Elite", "Student Account", "Private Wealth"]
geo_mapping = {
    "North America": [("United States", "USD"), ("Canada", "CAD"), ("Mexico", "MXN")],
    "Europe": [("United Kingdom", "GBP"), ("Germany", "EUR"), ("France", "EUR"), ("Spain", "EUR"), ("Italy", "EUR")],
    "Asia-Pacific": [("Japan", "JPY"), ("Australia", "AUD"), ("India", "INR"), ("Singapore", "SGD")],
    "Latin America": [("Brazil", "BRL"), ("Argentina", "ARS"), ("Colombia", "COP")],
    "Middle East": [("United Arab Emirates", "AED"), ("Saudi Arabia", "SAR")]
}

# --- NEW: Phase 1 - Generate Static Customer Profiles ---
print("Generating static customer database...")
num_customers = 5000
customers = {}
for i in range(num_customers):
    region = random.choices(list(geo_mapping.keys()), weights=[60, 20, 10, 5, 5])[0]
    country, currency = random.choice(geo_mapping[region])
    
    customers[f"CUST{1000 + i}"] = {
        "name": fake.name(),
        "tier": random.choices(account_tiers, weights=[40, 30, 10, 15, 5])[0], # Weighted tiers
        "region": region,
        "country": country,
        "currency": currency
    }

# Step 2: Generate Dataset
records = []
print("Generating 125,275 hyper-realistic financial transaction rows... (This may take 15-30 seconds)")

for i in range(125275):
    transaction_id = f"TXN{200000 + i}"
    
    # 1. Fetch a consistent customer
    customer_id = random.choice(list(customers.keys()))
    customer = customers[customer_id]
    
    # 2. Determine Category
    is_income = random.random() < 0.12
    if is_income:
        transaction_type = "Credit"
        main_category = "Income"
    else:
        transaction_type = "Debit"
        # Weight everyday expenses higher than big-ticket items
        main_category = random.choices(
            ["Housing", "Utilities", "Transportation", "Entertainment", "Shopping"],
            weights=[10, 15, 30, 20, 25]
        )[0]
    
    sub_category = random.choice(list(financial_config[main_category].keys()))
    config = financial_config[main_category][sub_category]
    merchant_name = random.choice(config["merchants"])
    
    # 3. Apply Realistic Amounts (Psychological pricing for retail/entertainment)
    raw_amount = random.uniform(config["range"][0], config["range"][1])
    if main_category in ["Shopping", "Entertainment"] and sub_category not in ["Concerts"]:
        # Make prices end in .99 or .00 realistically
        amount = round(raw_amount) - 0.01 if random.random() < 0.7 else round(raw_amount, 0)
    elif main_category in ["Housing", "Income"]:
        # Rent and Salary usually end in clean numbers
        amount = round(raw_amount / 10) * 10.0
    else:
        amount = round(raw_amount, 2)

    # 4. Temporal Logic (Time of month/day based on category)
    transaction_date = fake.date_time_between(start_date='-3y', end_date='now')
    if sub_category in ["Rent", "Mortgage"]:
        # Force housing payments to the 1st-5th of the month
        transaction_date = transaction_date.replace(day=random.randint(1, 5))
    if main_category == "Entertainment":
        # Push entertainment later in the day (6 PM - 11 PM)
        transaction_date = transaction_date.replace(hour=random.randint(18, 23))
        
    # 5. Smart Payment Methods
    if main_category in ["Housing", "Utilities", "Income"]:
        payment_method = "ACH Transfer"
    elif amount > 1000 and transaction_type == "Debit":
        payment_method = random.choice(["Bank Wire", "Credit Card"])
    else:
        payment_method = random.choice(["Debit Card", "Credit Card", "Apple Pay / Wallet"])

    # Calculate Fees
    if payment_method in ["Credit Card", "Apple Pay / Wallet"] and transaction_type == "Debit":
        transaction_fee = round(amount * 0.015, 2)
    else:
        transaction_fee = 0.00

    # 6. Status and Fraud Logic
    status = random.choices(["Completed", "Pending", "Failed"], weights=[92, 5, 3])[0]
    is_fraud = "No"
    if status == "Completed" and transaction_type == "Debit":
        # Spike fraud probability for international/high-ticket electronics
        if sub_category == "Electronics" and amount > 800 and random.random() < 0.15:
            is_fraud = "Yes"
        elif random.random() < 0.002: 
            is_fraud = "Yes"

    records.append({
        "Transaction ID": transaction_id,
        "Date": transaction_date.strftime('%Y-%m-%d'),
        "Time": transaction_date.strftime('%H:%M:%S'),
        "Customer ID": customer_id,
        "Customer Name": customer["name"],
        "Account Tier": customer["tier"],
        "Transaction Type": transaction_type,
        "Category": main_category,
        "Sub-Category": sub_category,
        "Merchant Name": merchant_name,
        "Amount": amount,
        "Currency": customer["currency"],
        "Transaction Fee": transaction_fee,
        "Net Impact": amount if transaction_type == "Credit" else -(amount + transaction_fee),
        "Payment Method": payment_method,
        "Status": status,
        "Region": customer["region"],       
        "Country": customer["country"],     
        "Fraud Flag": is_fraud
    })

# Step 3: Parse, Sort, and Extract Master CSV
df = pd.DataFrame(records)
# Sort realistically by Date and Time
df = df.sort_values(by=['Date', 'Time']).reset_index(drop=True)

try:
    output_file = "Realistic_Financial_Ledger.csv"
    df.to_csv(output_file, index=False)
    print(f"Success! Master dataset saved as '{output_file}'")
except PermissionError:
    print(f"\nError: Close '{output_file}' if it is open in Excel or your BI workspace tools and re-run.")


# Assuming 'df' is your generated realistic dataframe from the previous step
print("\nTransforming flat dataset into an updated Star Schema (with dim_geography)...")

# ==========================================
# 1. Dimension 1: dim_geography (NEW)
# ==========================================
# Extract unique combinations of Region, Country, and Currency
dim_geography = df[['Region', 'Country', 'Currency']].drop_duplicates().reset_index(drop=True)
# Assign a surrogate key (Geo_ID) starting at 100
dim_geography.insert(0, 'Geo_ID', range(100, 100 + len(dim_geography)))

# Merge the Geo_ID back into the main dataframe so we can use it for fact_transactions
df = pd.merge(df, dim_geography, on=['Region', 'Country', 'Currency'], how='left')

# ==========================================
# 2. Dimension 2: dim_customer
# ==========================================
# We now REMOVE Region, Country, and Currency from the customer table to prevent redundancy
dim_customer = df[['Customer ID', 'Customer Name', 'Account Tier']].drop_duplicates()
dim_customer = dim_customer.reset_index(drop=True)

# ==========================================
# 3. Dimension 3: dim_date
# ==========================================
unique_dates = df[['Date']].drop_duplicates().copy()
unique_dates['Date'] = pd.to_datetime(unique_dates['Date'])

dim_date = pd.DataFrame({
    'Date_ID': unique_dates['Date'].dt.strftime('%Y%m%d').astype(int),
    'Date': unique_dates['Date'].dt.strftime('%Y-%m-%d'),
    'Year': unique_dates['Date'].dt.year,
    'Quarter': unique_dates['Date'].dt.quarter,
    'Month': unique_dates['Date'].dt.month,
    'Month_Name': unique_dates['Date'].dt.month_name(),
    'Day': unique_dates['Date'].dt.day,
    'Day_Of_Week': unique_dates['Date'].dt.day_name(),
    'Is_Weekend': unique_dates['Date'].dt.dayofweek.isin([5, 6]).astype(int)
}).drop_duplicates().reset_index(drop=True)

# ==========================================
# 4. Dimension 4: dim_merchant
# ==========================================
dim_merchant = df[['Merchant Name', 'Category', 'Sub-Category']].drop_duplicates().reset_index(drop=True)
dim_merchant.insert(0, 'Merchant_ID', range(1000, 1000 + len(dim_merchant)))

# ==========================================
# 5. Fact Table: fact_transactions
# ==========================================
fact_transactions = df.copy()

# Map Date_ID
fact_transactions['Date'] = pd.to_datetime(fact_transactions['Date'])
fact_transactions['Date_ID'] = fact_transactions['Date'].dt.strftime('%Y%m%d').astype(int)

# Map Merchant_ID
fact_transactions = pd.merge(fact_transactions, dim_merchant, on=['Merchant Name', 'Category', 'Sub-Category'], how='left')

# Keep only the Foreign Keys and numerical metrics
# Notice we added 'Geo_ID' and removed the raw text geo columns
fact_columns = [
    'Transaction ID', 
    'Customer ID',       # FK to dim_customer
    'Date_ID',           # FK to dim_date
    'Merchant_ID',       # FK to dim_merchant
    'Geo_ID',            # FK to dim_geography (NEW)
    'Time', 
    'Transaction Type', 
    'Payment Method', 
    'Status', 
    'Fraud Flag', 
    'Amount', 
    'Transaction Fee', 
    'Net Impact'
]
fact_transactions = fact_transactions[fact_columns]

# ==========================================
# 6. Export the Star Schema
# ==========================================
try:
    dim_geography.to_csv("dim_geography.csv", index=False)
    dim_customer.to_csv("dim_customer.csv", index=False)
    dim_date.to_csv("dim_date.csv", index=False)
    dim_merchant.to_csv("dim_merchant.csv", index=False)
    fact_transactions.to_csv("fact_transactions.csv", index=False)
    
    print("\nSuccess! 5-Table Star Schema generated:")
    print(f" - dim_geography: {len(dim_geography)} rows")
    print(f" - dim_customer: {len(dim_customer)} rows")
    print(f" - dim_date: {len(dim_date)} rows")
    print(f" - dim_merchant: {len(dim_merchant)} rows")
    print(f" - fact_transactions: {len(fact_transactions)} rows")
    
except PermissionError:
    print("Error: Ensure none of the CSV files are open and run again.")