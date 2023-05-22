class CreateMhxResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :mhx_responses do |t|
      t.belongs_to :submission
      t.string :error_report

      t.timestamps
    end

    create_table :mhx_response_external_ids do |t|
      t.belongs_to :response
      t.belongs_to :external_id
    end
  end
end
