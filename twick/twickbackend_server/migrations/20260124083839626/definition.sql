-- Migration: 20260124083839626
-- Creates custom tables for twickbackend module

-- Create task table
CREATE TABLE IF NOT EXISTS "task" (
  "id" serial PRIMARY KEY,
  "clientId" text NOT NULL,
  "authUserId" uuid NOT NULL,
  "title" text NOT NULL,
  "scheduledTime" timestamp without time zone NOT NULL,
  "isCompleted" boolean NOT NULL,
  "priority" text NOT NULL,
  "categoryId" text,
  "playSound" boolean NOT NULL,
  "isRecurring" boolean NOT NULL,
  "recurringIntervalType" text,
  "recurringDuration" integer NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);

-- Create indexes for task table
CREATE INDEX IF NOT EXISTS "task_auth_user_id_idx" ON "task" USING btree ("authUserId");
CREATE INDEX IF NOT EXISTS "task_client_id_idx" ON "task" USING btree ("clientId");
CREATE INDEX IF NOT EXISTS "task_category_id_idx" ON "task" USING btree ("categoryId");
CREATE INDEX IF NOT EXISTS "task_auth_user_completed_idx" ON "task" USING btree ("authUserId", "isCompleted");
CREATE INDEX IF NOT EXISTS "task_auth_user_scheduled_idx" ON "task" USING btree ("authUserId", "scheduledTime");

-- Create task_category table
CREATE TABLE IF NOT EXISTS "task_category" (
  "id" serial PRIMARY KEY,
  "clientId" text NOT NULL,
  "authUserId" uuid NOT NULL,
  "name" text NOT NULL,
  "iconCodePoint" integer NOT NULL,
  "colorValue" integer NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);

-- Create indexes for task_category table
CREATE INDEX IF NOT EXISTS "task_category_auth_user_id_idx" ON "task_category" USING btree ("authUserId");
CREATE INDEX IF NOT EXISTS "task_category_client_id_idx" ON "task_category" USING btree ("clientId");

-- Create user_settings table
CREATE TABLE IF NOT EXISTS "user_settings" (
  "id" serial PRIMARY KEY,
  "authUserId" uuid NOT NULL UNIQUE,
  "notificationsEnabled" boolean NOT NULL,
  "sleepModeEnabled" boolean NOT NULL,
  "sleepModeFromHour" integer NOT NULL,
  "sleepModeFromMinute" integer NOT NULL,
  "sleepModeToHour" integer NOT NULL,
  "sleepModeToMinute" integer NOT NULL,
  "createdAt" timestamp without time zone NOT NULL,
  "updatedAt" timestamp without time zone NOT NULL
);

-- Create index for user_settings table
CREATE INDEX IF NOT EXISTS "user_settings_auth_user_id_idx" ON "user_settings" USING btree ("authUserId");
