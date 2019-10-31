class AddSubjectIdToHmisClient < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_clients, :subject_id, :integer
  end
end
