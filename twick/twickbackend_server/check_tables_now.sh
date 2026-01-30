#!/bin/bash
# Script to check PostgreSQL tables with provided credentials
# Usage: ./check_tables_now.sh <database_host>

DB_PASSWORD="npg_WCDBKhJ9V5ri"
DB_USER="kevin"
DB_NAME="default"

if [ -z "$1" ]; then
    echo "=========================================="
    echo "Database Tables Check"
    echo "=========================================="
    echo ""
    echo "Usage: ./check_tables_now.sh <database_host>"
    echo ""
    echo "First, get the database host by running:"
    echo "  scloud db info"
    echo ""
    echo "Then run this script with the host:"
    echo "  ./check_tables_now.sh ep-restless-water-xxx.pooler.c-2.eu-central-1.aws.neon.tech"
    echo ""
    exit 1
fi

DB_HOST="$1"

echo "=========================================="
echo "Checking PostgreSQL Tables"
echo "=========================================="
echo "Host: $DB_HOST"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql command not found"
    echo "Install PostgreSQL client tools to use this script"
    echo "On macOS: brew install postgresql"
    exit 1
fi

# Test connection
echo "Step 1: Testing database connection..."
if PGPASSWORD="$DB_PASSWORD" psql "postgresql://$DB_HOST/$DB_NAME?sslmode=require" --user "$DB_USER" -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Connection successful!"
else
    echo "❌ Connection failed. Please check:"
    echo "  1. Database host is correct"
    echo "  2. Password is correct"
    echo "  3. User has access permissions"
    exit 1
fi

echo ""
echo "Step 2: Listing all tables..."
echo ""
PGPASSWORD="$DB_PASSWORD" psql \
  "postgresql://$DB_HOST/$DB_NAME?sslmode=require" \
  --user "$DB_USER" \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"

echo ""
echo "Step 3: Checking Serverpod core tables..."
echo ""
PGPASSWORD="$DB_PASSWORD" psql \
  "postgresql://$DB_HOST/$DB_NAME?sslmode=require" \
  --user "$DB_USER" \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'serverpod_%' ORDER BY tablename;"

echo ""
echo "Step 4: Checking custom tables..."
echo ""
PGPASSWORD="$DB_PASSWORD" psql \
  "postgresql://$DB_HOST/$DB_NAME?sslmode=require" \
  --user "$DB_USER" \
  -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('task', 'task_category', 'user_settings') ORDER BY tablename;"

echo ""
echo "Step 5: Checking migration status..."
echo ""
PGPASSWORD="$DB_PASSWORD" psql \
  "postgresql://$DB_HOST/$DB_NAME?sslmode=require" \
  --user "$DB_USER" \
  -c "SELECT module, version, timestamp FROM serverpod_migrations ORDER BY timestamp DESC LIMIT 10;"

echo ""
echo "Step 6: Checking user profiles count..."
echo ""
PGPASSWORD="$DB_PASSWORD" psql \
  "postgresql://$DB_HOST/$DB_NAME?sslmode=require" \
  --user "$DB_USER" \
  -c "SELECT COUNT(*) as user_count FROM serverpod_user_info;" 2>/dev/null || echo "⚠️  serverpod_user_info table does not exist"

echo ""
echo "=========================================="
echo "Check complete!"
echo "=========================================="
