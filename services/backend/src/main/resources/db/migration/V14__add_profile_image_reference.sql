ALTER TABLE user_profiles
    ADD COLUMN avatar_image_id VARCHAR(120);

CREATE UNIQUE INDEX uk_user_profiles_avatar_image_id
    ON user_profiles (avatar_image_id)
    WHERE avatar_image_id IS NOT NULL;
