-- CreateEnum
CREATE TYPE "Language" AS ENUM ('EN', 'ES', 'FR', 'DE', 'IT', 'PT', 'ZH', 'JA', 'KO', 'AR', 'HI', 'RU');

-- CreateEnum
CREATE TYPE "Speaker" AS ENUM ('USER', 'OTHER');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "daily_translations" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "last_usage_reset" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "total_translations" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "voice_preferences" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "preferred_voice_id" TEXT NOT NULL,
    "voice_name" TEXT NOT NULL,
    "speech_rate" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "default_source_lang" "Language" NOT NULL DEFAULT 'EN',
    "default_target_lang" "Language" NOT NULL DEFAULT 'ES',
    "auto_detect_source" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "voice_preferences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" TEXT,
    "source_language" "Language" NOT NULL,
    "target_language" "Language" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "speaker" "Speaker" NOT NULL,
    "original_text" TEXT NOT NULL,
    "translated_text" TEXT NOT NULL,
    "source_language" "Language" NOT NULL,
    "target_language" "Language" NOT NULL,
    "original_audio_url" TEXT,
    "translated_audio_url" TEXT,
    "duration_ms" INTEGER,
    "confidence" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usage_records" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "translations" INTEGER NOT NULL DEFAULT 0,
    "audio_minutes" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "tts_characters" INTEGER NOT NULL DEFAULT 0,
    "estimated_cost" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "usage_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "voice_preferences_user_id_key" ON "voice_preferences"("user_id");

-- CreateIndex
CREATE INDEX "conversations_user_id_idx" ON "conversations"("user_id");

-- CreateIndex
CREATE INDEX "messages_conversation_id_idx" ON "messages"("conversation_id");

-- CreateIndex
CREATE INDEX "usage_records_user_id_idx" ON "usage_records"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "usage_records_user_id_date_key" ON "usage_records"("user_id", "date");

-- AddForeignKey
ALTER TABLE "voice_preferences" ADD CONSTRAINT "voice_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usage_records" ADD CONSTRAINT "usage_records_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
