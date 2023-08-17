class DowncaseUserEmails < ActiveRecord::Migration[6.1]
  # normalize all emails to lowercase. This may fail if there are duplicates
  # which need to be handled manually
  def up
    safety_assured do
      execute <<~SQL
        UPDATE users SET email = LOWER(email) WHERE deleted_at IS NULL
      SQL
    end
  end
end
