class CreateReportDefinition < ActiveRecord::Migration
  def change
    create_table :report_definitions do |t|
      t.timestamp
    end

    create_table :report_definitions_users do |t|
      t.integer :report_definition_id
      t.integer :user_id, null: false
      t.index [:user_id, :report_definition_id], name: 'user_report_definition'
      t.index [:report_definition_id, :user_id], name: 'report_definition_user'
      t.timestamp
    end
  end
end
