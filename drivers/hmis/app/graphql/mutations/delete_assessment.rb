module Mutations
  class DeleteAssessment < BaseMutation
    argument :id, ID, required: true

    field :assessment, Types::HmisSchema::Assessment, null: true

    def resolve(id:)
      assessment = Hmis::Hud::Assessment.viewable_by(current_user).find_by(id: id)
      errors = []

      errors << HmisErrors::Error.new(:id, :not_found) unless assessment.present?

      assessment.destroy! if assessment.present?

      return {
        assessment: assessment,
        errors: errors,
      }
    end
  end
end
