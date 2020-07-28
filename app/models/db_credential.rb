class DbCredential < ApplicationRecord
  belongs_to :user
  attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31], encode: false, encode_iv: false
  after_initialize :defaults
  has_paper_trail

  PG_ROLE = 'bi'
  def self.hours_available
    4
  end

  def defaults
    unless persisted?
      self.username ||= secure_value
      self.password ||= secure_value
      self.database ||= DB_WAREHOUSE['database']
      self.host ||= ENV['RDS_DIRECT_ACCESS_HOST'].presence || DB_WAREHOUSE['host']
      self.port ||= DB_WAREHOUSE['port'] || 5432
      self.role ||= PG_ROLE
      self.adaptor ||= :postgres
    end
  end

  private def secure_value
    SecureRandom.alphanumeric(16)
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
  def provision!
    pg_conn.execute(create_role_sql(role: role)) unless pg_role_exists?
    pg_conn.execute(
      "CREATE USER #{pg_ident self.username} IN ROLE #{pg_ident role} PASSWORD #{pg_conn.quote password} CONNECTION LIMIT 2"
    ) unless pg_user_exists?
  end

  def reprovision!
    revoke_db_user!
    self.username = secure_value
    self.password = secure_value
    save!
    provision!
  end

  # raises PG::UndefinedObject
  def revoke!
    revoke_db_user!
    self.destroy
  end

  private def revoke_db_user!
    pg_conn.execute("DROP USER #{pg_ident self.username}") if pg_user_exists?
  end

  def pg_user_exists?
    pg_conn.execute(pg_role_exists_sql(self.username)).count&.positive?
  end

  def pg_role_exists?
    pg_conn.execute(pg_role_exists_sql(self.role)).count&.positive?
  end

  private def pg_role_exists_sql(pg_role)
    "SELECT 1 FROM pg_roles WHERE rolname = #{pg_str(pg_role)}"
  end

  private def pg_conn
    GrdaWarehouseBase.connection
  end

  private def pg_ident(str)
    PG::Connection.quote_ident(str)
  end

  private def pg_str(str)
    pg_conn.quote(str)
  end


end
