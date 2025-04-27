# frozen_string_literal: true

class AddSearchVectorToUsers < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      add_column :users, :search_vector, :tsvector

      execute <<-SQL
        CREATE FUNCTION users_search_vector_update() RETURNS trigger AS $$
        BEGIN
          NEW.search_vector :=
            setweight(to_tsvector('simple', coalesce(NEW.first_name,'')), 'A') ||
            setweight(to_tsvector('simple', coalesce(NEW.last_name,'')), 'A') ||
            setweight(to_tsvector('simple', coalesce(NEW.email,'')), 'B');
          RETURN NEW;
        END
        $$ LANGUAGE plpgsql;
      SQL

      execute <<-SQL
        CREATE TRIGGER users_search_vector_update
        BEFORE INSERT OR UPDATE ON users
        FOR EACH ROW EXECUTE FUNCTION users_search_vector_update();
      SQL

      execute <<-SQL
        UPDATE users SET search_vector =
          setweight(to_tsvector('simple', coalesce(first_name,'')), 'A') ||
          setweight(to_tsvector('simple', coalesce(last_name,'')), 'A') ||
          setweight(to_tsvector('simple', coalesce(email,'')), 'B');
      SQL

      execute <<-SQL
        CREATE INDEX users_search_idx ON users USING gin(search_vector);
      SQL
    end
  end

  def down
    safety_assured do
      execute 'DROP INDEX IF EXISTS users_search_idx;'
      execute 'DROP TRIGGER IF EXISTS users_search_vector_update ON users;'
      execute 'DROP FUNCTION IF EXISTS users_search_vector_update();'
      remove_column :users, :search_vector
    end
  end
end
