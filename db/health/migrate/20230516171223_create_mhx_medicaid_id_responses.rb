class CreateMhxMedicaidIdResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :mhx_medicaid_id_responses do |t|
      t.references :medicaid_id_inquiry
      t.string :response

      t.timestamps
    end
  end
end
