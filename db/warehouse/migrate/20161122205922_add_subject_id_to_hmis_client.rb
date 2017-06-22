class AddSubjectIdToHmisClient < ActiveRecord::Migration
  def change
    add_column :hmis_clients, :subject_id, :integer
  end
end
