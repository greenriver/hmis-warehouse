class CreateReportDefinition < ActiveRecord::Migration[4.2]
  def change
    create_table :report_definitions do |t|
      t.string 'report_group'
      t.text 'url'
      t.text 'name'
      t.text 'description'
      t.timestamp
    end
  end
end
