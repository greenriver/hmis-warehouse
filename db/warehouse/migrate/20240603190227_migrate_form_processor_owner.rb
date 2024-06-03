class MigrateFormProcessorOwner < ActiveRecord::Migration[7.0]
  # rails db:migrate:up:warehouse VERSION=20240603190227
  def up
    # Populate the owner_id,owner_type columns from custom_assessment_id
    # Note: this will fail if custom_assessment_id values are not unique, since the owner has an index on that.
    fp_t = Hmis::Form::FormProcessor.arel_table
    Hmis::Form::FormProcessor.where(owner_id: nil). # owner_id should all be null here, but check anyway
      where.not(custom_assessment_id: nil). # custom_assessment_id should all be present here, but check anyway
      update_all(owner_type: 'Hmis::Hud::CustomAssessment', owner_id: fp_t[:custom_assessment_id])
    # >>>>TODO: owner shoud be made non-nullable
  end

  # rails db:migrate:down:warehouse VERSION=20240603190227
  def down
    # 'down' shouldn't really be needed, since custom_assessment_id is already present.
    # however the below code will clean up the FormProcessor table in the event that records were submitted since the last migration
    fp_t = Hmis::Form::FormProcessor.arel_table
    Hmis::Form::FormProcessor.where(fp_t[:custom_assessment_id].eq(nil).and(fp_t[:owner_type].eq('Hmis::Hud::CustomAssessment'))).
      update_all(custom_assessment_id: fp_t[:owner_id])
    # Hmis::Form::FormProcessor.where(custom_assessment_id: nil).delete_all
  end
end
