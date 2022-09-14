module Mutations
  class UpdateEnrollment < BaseMutation
    argument :id, ID, required: true
    date_string_argument :entry_date, 'Entry date with format yyyy-mm-dd', required: false
    argument :relationship_to_ho_h, HmisSchema::Enums::RelationshipToHoH, required: false

    field :enrollment, Types::HmisSchema::Enrollment, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, entry_date: nil, relationship_to_ho_h: nil)
      errors = []
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)

      if enrollment
        enrollment.entry_date = entry_date if entry_date.present?
        enrollment.relationship_to_ho_h = relationship_to_ho_h if relationship_to_ho_h.present?
        enrollment.save!
      else
        errors << InputValidationError.new("No enrollment found with ID '#{id}'", attribute: 'id')
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
