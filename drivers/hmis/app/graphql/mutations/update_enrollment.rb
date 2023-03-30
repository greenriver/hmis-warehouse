module Mutations
  class UpdateEnrollment < BaseMutation
    argument :id, ID, required: true
    argument :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: false

    field :enrollment, Types::HmisSchema::Enrollment, null: true

    def resolve(id:, relationship_to_ho_h: nil)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: id)

      return { errors: [HmisErrors::Error.new(:enrollment, :not_found)] } unless enrollment.present?
      return { errors: [HmisErrors::Error.new(:enrollment, :not_allowed)] } unless current_user.permissions_for?(enrollment, :can_edit_enrollments)

      enrollment.relationship_to_ho_h = relationship_to_ho_h if relationship_to_ho_h.present?
      enrollment.user_id = hmis_user.user_id
      enrollment.save!
      enrollment.touch

      errors = []
      unless enrollment.valid?
        errors << enrollment.errors.errors
        enrollment = nil
      end

      {
        enrollment: enrollment,
        errors: errors,
      }
    end
  end
end
