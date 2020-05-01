class TracingContactsChanges < ActiveRecord::Migration[5.2]
  def change
    change_table :tracing_contacts do |t|
      t.string :investigator
      t.string :alert_in_epic
    end
  end
end
