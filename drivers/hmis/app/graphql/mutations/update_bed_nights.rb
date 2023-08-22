###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateBedNights < BaseMutation
    argument :enrollment_ids, [ID], required: true
    argument :bed_night_date, GraphQL::Types::ISO8601Date, required: true
    argument :action, Types::HmisSchema::Enums::BulkActionType, required: true

    field :success, Boolean, null: true

    def resolve(enrollment_ids:, bed_night_date:, action:)
      enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).where(id: enrollment_ids)
      raise 'not found' unless enrollments.count == enrollment_ids.uniq.length

      project_pk = enrollments.first.project.id
      raise 'project mismatch' unless enrollments.size == enrollments.with_project([project_pk]).size

      hud_user_id = Hmis::Hud::User.from_user(current_user).user_id

      Hmis::Hud::Service.transaction do
        case action
        when 'ADD'
          services = enrollments.map do |enrollment|
            Hmis::Hud::Service.new(
              **enrollment.slice(:enrollment_id, :personal_id, :data_source_id),
              date_provided: bed_night_date,
              record_type: 200, # bed night
              type_provided: 200, # bed night
              user_id: hud_user_id,
            )
          end
          services.map { |s| s.save!(context: :bed_nights_mutation) }
        when 'REMOVE'
          services = Hmis::Hud::Service.bed_nights.
            where(enrollment_id: enrollments.map(&:enrollment_id), data_source_id: current_user.hmis_data_source_id).
            where(date_provided: bed_night_date)
          services.destroy_all
        end
      end

      { success: true }
    end
  end
end
