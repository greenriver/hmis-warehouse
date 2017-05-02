class CreateReportingTables < ActiveRecord::Migration
  def change
    # available reports
    create_table :reports do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.timestamps null: false 
    end

    # reports in process
    create_table :report_queues do |t|
      t.references :report_result, index: true
      t.integer :unduplicated_client_id
    end

    # reports results
    create_table :report_results do |t|
      t.references :report, index: true
      t.datetime :report_group
      t.integer :import_id
      t.float :percent_complete
      t.json :results
      t.timestamps null: false 
    end
  end
end
