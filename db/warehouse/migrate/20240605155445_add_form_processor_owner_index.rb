class AddFormProcessorOwnerIndex < ActiveRecord::Migration[7.0]
  # disable_ddl_transaction! # needed for index creation

  def change
    safety_assured do
      add_index :hmis_form_processors, [:owner_id, :owner_type], unique: true, name: 'one_form_processor_per_owner'
    end
  end
end
