class AddActorTypeToCasReports < ActiveRecord::Migration[5.2]
  def change
    add_column :cas_reports, :actor_type, :string
  end
end
