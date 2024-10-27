-- migrate:up
ALTER TABLE
  refresh_tokens
ADD
  COLUMN revoked_at TIMESTAMPTZ;

-- migrate:down
ALTER TABLE
  refresh_tokens DROP COLUMN revoked_at;