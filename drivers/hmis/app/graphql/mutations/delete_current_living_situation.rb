###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteCurrentLivingSituation < BaseMutation
    argument :id, ID, required: true

    field :current_living_situation, Types::HmisSchema::CurrentLivingSituation, null: true

    def resolve(id:)
      current_living_situation = Hmis::Hud::CurrentLivingSituation.viewable_by(current_user).find_by(id: id)
      access_denied! unless current_living_situation
      access_denied! unless current_permission?(permission: :can_edit_enrollments, entity: current_living_situation)

      current_living_situation.with_lock do
        # If this CLS is the owner of a FormProcessor, destroy related records (for example clh_location)
        current_living_situation.form_processor&.destroy_related_records!
        current_living_situation.destroy!
      end

      {
        current_living_situation: current_living_situation,
        errors: [],
      }
    end
  end
end
