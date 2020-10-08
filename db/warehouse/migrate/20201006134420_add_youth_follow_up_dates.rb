class AddYouthFollowUpDates < ActiveRecord::Migration[5.2]
  def change
    add_column :youth_follow_ups, :action, :string
    add_column :youth_follow_ups, :action_on, :date
    add_column :youth_follow_ups, :required_on, :date
    add_column :youth_follow_ups, :case_management_id, :integer

    add_column :youth_case_managements, :zip_code, :string
  end
end
