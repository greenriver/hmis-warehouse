class DbCredential < ApplicationRecord
  belongs_to :user
  attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31], encode: false, encode_iv: false
  after_initialize :defaults

  PG_ROLE = 'bi'
  def defaults
    unless persisted?
      self.username ||= SecureRandom.alphanumeric(16)
      self.password ||= SecureRandom.alphanumeric(16)
      self.database ||= DB_WAREHOUSE['database']
      self.host ||= DB_WAREHOUSE['host']
      self.port ||= DB_WAREHOUSE['port']
    end
  end


  private def create_role_sql(role: PG_ROLE)
    <<~SQL
      DO $$
      BEGIN
        CREATE ROLE #{pg_ident role} WITH NOLOGIN;
        EXCEPTION WHEN DUPLICATE_OBJECT THEN
        RAISE NOTICE 'not creating role #{role} -- it already exists';
      END
      $$;
    SQL
  end

  # raises PG::DuplicateObject if the connection already exists
  def provision
    pg_conn.execute create_role_sql(role: role)
    pg_conn.execute(
      "CREATE USER #{pg_ident username} IN ROLE #{pg_ident role} PASSWORD #{pg_conn.quote password} CONNECTION LIMIT 2"
    )
  end

  # raises PG::UndefinedObject
  def revoke
    pg_conn.execute "DROP USER #{pg_ident db_user}"
  end

  private def pg_conn
    GrdaWarehouseBase.connection
  end

  private def pg_ident(str)
    PG::Connection.quote_ident(str)
  end

  private def pg_str(str)
    PG::Connection.quote(str)
  end


end
