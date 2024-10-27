-- migrate:up
ALTER TABLE
  refresh_tokens
ADD
  COLUMN replaced_at TIMESTAMPTZ,
ADD
  COLUMN replaced_by UUID REFERENCES refresh_tokens(id) ON DELETE
SET
  NULL;

-- migrate:down
ALTER TABLE
  refresh_tokens DROP COLUMN replaced_at,
  DROP COLUMN replaced_by;