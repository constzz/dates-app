DROP INDEX IF EXISTS auth_refresh_tokens_active_idx;
DROP INDEX IF EXISTS auth_refresh_tokens_expires_at_idx;
DROP INDEX IF EXISTS auth_refresh_tokens_user_id_idx;
DROP TABLE IF EXISTS auth_refresh_tokens;

DROP INDEX IF EXISTS users_created_at_idx;
DROP TABLE IF EXISTS users;
