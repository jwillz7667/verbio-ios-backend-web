-- CreateTable
CREATE TABLE "saved_phrases" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "original_text" TEXT NOT NULL,
    "translated_text" TEXT NOT NULL,
    "source_language" "Language" NOT NULL,
    "target_language" "Language" NOT NULL,
    "is_favorite" BOOLEAN NOT NULL DEFAULT false,
    "usage_count" INTEGER NOT NULL DEFAULT 0,
    "last_used_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "saved_phrases_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "saved_phrases_user_id_idx" ON "saved_phrases"("user_id");

-- CreateIndex
CREATE INDEX "saved_phrases_user_id_is_favorite_idx" ON "saved_phrases"("user_id", "is_favorite");

-- CreateIndex
CREATE UNIQUE INDEX "saved_phrases_user_id_original_text_target_language_key" ON "saved_phrases"("user_id", "original_text", "target_language");

-- AddForeignKey
ALTER TABLE "saved_phrases" ADD CONSTRAINT "saved_phrases_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
