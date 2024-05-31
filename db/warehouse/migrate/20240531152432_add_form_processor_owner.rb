class AddFormProcessorOwner < ActiveRecord::Migration[7.0]
  disable_ddl_transaction! # ok?
  # is algorithm: :concurrently ok to use? I think we want an index there

  # rails db:migrate:up:warehouse VERSION=20240531152432
  def up
    # Add polymorphic 'owner' to form processor table
    add_reference :hmis_form_processors, :owner, polymorphic: true, index: { algorithm: :concurrently }, null: true # make non-nullable after filling with data

    # Fill it with custom_assessment_id for all existing records
    fp_t = Hmis::Form::FormProcessor.arel_table
    Hmis::Form::FormProcessor.where.not(custom_assessment_id: nil).update_all(owner_type: 'Hmis::Hud::CustomAssessment', owner_id: fp_t[:custom_assessment_id])

    # Make custom_assessment_id nullable (it will be removed later)
    change_column_null :hmis_form_processors, :custom_assessment_id, true

    # >>>>TODO: owner shoud be made non-nullable
    # >>>>TODO: owner_id,owner_type index should be made unique
  end

  # rails db:migrate:down:warehouse VERSION=20240531152432
  def down
    # For good measure, migrate in any owner_id values into custom_assessment_id where missing (in case records were created in previous state)
    fp_t = Hmis::Form::FormProcessor.arel_table
    Hmis::Form::FormProcessor.where(fp_t[:custom_assessment_id].eq(nil).and(fp_t[:owner_type].eq('Hmis::Hud::CustomAssessment'))).update_all(custom_assessment_id: fp_t[:owner_id])

    # Remove polymorphic column
    remove_column :hmis_form_processors, :owner_type
    remove_column :hmis_form_processors, :owner_id

    # Make custom_assessment_id non-nullable again
    change_column_null :hmis_form_processors, :custom_assessment_id, false
    
  end
end
