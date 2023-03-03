module Mutations
  class UpdateEnrollment < BaseMutation
    argument :id, ID, required: true
    date_string_argument :entry_date, 'Entry date with format yyyy-mm-dd', required: false
    argument :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: false

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(id:, entry_date: nil, relationship_to_ho_h: nil)
      errors = []
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)

      if enrollment
        if current_user.permissions_for?(enrollment, :can_edit_enrollments)
          enrollment.entry_date = entry_date if entry_date.present?
          enrollment.relationship_to_ho_h = relationship_to_ho_h if relationship_to_ho_h.present?
          enrollment.date_updated = DateTime.current
          enrollment.user_id = hmis_user.user_id
          enrollment.save!

          errors << enrollment.errors.errors unless enrollment.valid?
        else
          enrollment = nil
          errors << HmisErrors::Error.new(:enrollment, :not_allowed)
        end
      else
        errors << HmisErrors::Error.new(:enrollment, :not_found)
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
