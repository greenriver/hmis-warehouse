class AddColumnToAnsdEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :ansd_events, :client_id, :string
    add_column :ansd_events, :source_enrollment_id, :string
  end
end
