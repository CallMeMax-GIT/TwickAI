#!/bin/bash
# Script to check database status and tables in Serverpod Cloud
# This helps diagnose database connection and schema issues

echo "=========================================="
echo "Database Status Check"
echo "=========================================="
echo ""

# Get database connection info
echo "Step 1: Getting database connection info..."
echo "Run: scloud db info"
echo ""

# Get database password
echo "Step 2: Getting/resetting database password..."
echo "Run: scloud db user reset-password"
echo ""

# Check what tables exist
echo "Step 3: Connect to database and check tables..."
echo ""
echo "After getting the password, run this command (replace <password> and <host>):"
echo ""
echo "PGPASSWORD=<password> psql \\"
echo "  \"postgresql://<host>/default?sslmode=require\" \\"
echo "  --user postgres \\"
echo "  -c \"\\dt\""
echo ""
echo "Or to check specific tables:"
echo ""
echo "PGPASSWORD=<password> psql \\"
echo "  \"postgresql://<host>/default?sslmode=require\" \\"
echo "  --user postgres \\"
echo "  -c \"SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;\""
echo ""
echo "=========================================="
echo ""
echo "Expected tables:"
echo "  ✓ serverpod_cloud_storage (Serverpod core)"
echo "  ✓ serverpod_cloud_storage_direct_upload (Serverpod core)"
echo "  ✓ serverpod_user_info (Serverpod auth)"
echo "  ✓ serverpod_user_image (Serverpod auth)"
echo "  ✓ task (custom)"
echo "  ✓ task_category (custom)"
echo "  ✓ user_settings (custom)"
echo ""
echo "If tables are missing:"
echo "  1. Deploy normally: scloud deploy (migrations run automatically)"
echo "  2. Check logs: scloud log"
echo "  3. If core Serverpod tables are missing, contact Serverpod Cloud support"
echo ""
