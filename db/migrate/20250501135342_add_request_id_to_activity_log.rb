class AddRequestIdToActivityLog < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_activity_logs, :request_id, :string
  end
end
