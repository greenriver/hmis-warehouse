CREATE OR REPLACE FUNCTION prevent_modification()
RETURNS trigger AS $$
BEGIN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
