class AddRemovalDateColumnToSecureFiles < ActiveRecord::Migration[6.1]
  def change
    add_column :secure_files, :removal_date, :datetime

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL
            UPDATE "secure_files" SET removal_date = created_at + INTERVAL '1 month'
          SQL
        end
      end
    end
  end
end
