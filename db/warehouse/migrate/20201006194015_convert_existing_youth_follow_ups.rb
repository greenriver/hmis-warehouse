class ConvertExistingYouthFollowUps < ActiveRecord::Migration[5.2]
  def up
    # This migration fails because it tries to write versions and the transaction gets unhappy
    # return unless GrdaWarehouse::Youth::YouthFollowUp.exists?

    # existing_follow_ups = GrdaWarehouse::Youth::YouthFollowUp.joins(:client).order(contacted_on: :asc).all.to_a
    # GrdaWarehouse::Youth::YouthFollowUp.update_all(deleted_at: Date.current)

    # # Loop over intakes, creating follow-ups as
    # # would have been appropriate
    # GrdaWarehouse::YouthIntake::Base.find_each do |intake|
    #   intake.save!
    # end

    # existing_follow_ups.each do |follow_up|
    #   # Convert to case management notes
    # status = if follow_up.housing_status.starts_with?('Yes')
    #   'This youth is currently in stable housing'
    # else
    #   'This youth is currently experiencing homeless'
    # end
    #   GrdaWarehouse::Youth::YouthCaseManagement.create(
    #     client_id: follow_up.client_id,
    #     user_id: follow_up.user_id,
    #     created_at: follow_up.created_at,
    #     updated_at: follow_up.updated_at,
    #     activity: 'From Follow-up',
    #     engaged_on: follow_up.contacted_on,
    #     housing_status: status,
    #     zip_code: follow_up.zip_code,
    #   )
    # end
    # Notes
    # # GrdaWarehouse::Youth::YouthCaseManagement.where(activity: 'From Follow-up').map { |c| c.update(housing_status: 'This youth is currently in stable housing') if c.housing_status.starts_with?('Yes')}
    # # GrdaWarehouse::Youth::YouthCaseManagement.where(activity: 'From Follow-up').map { |c| c.update(housing_status: 'This youth is currently experiencing homeless') if c.housing_status.starts_with?('No')}
    # # Loop over follow-ups and see if there is a case management note on or after the
    # # required_on date
    # # update follow-up with case management note data
    # GrdaWarehouse::Youth::YouthFollowUp.preload(:case_managements).find_each do |follow_up|
    #   next_note = follow_up.case_managements&.select do |note|
    #     note.required_on <= note.engaged_on
    #   end&.min_by(&:engaged_on)
    #   next unless next_note

    #   follow_up.update(
    #     housing_status: next_note.class.generic_housing_status(next_note.housing_status),
    #     contacted_on: next_note.engaged_on,
    #   )
    # end
  end
end
