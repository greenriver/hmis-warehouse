module Types
  class HmisSchema::EnrollmentSummary < Types::BaseObject
    field :id, ID, null: false
    field :entry_date, GraphQL::Types::ISO8601Date, null: false
    field :project_name, String, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: false
    field :project_id, String, null: false
    field :move_in_date, GraphQL::Types::ISO8601Date, null: true
    field :in_progress, Boolean, null: false, method: :in_progress?
    field :can_view_enrollment, Boolean, null: false

    def project_name
      return Hmis::Hud::Project::CONFIDENTIAL_PROJECT_NAME if project.confidential && !can_view_enrollment

      project.project_name
    end

    def project_type
      project.project_type
    end

    def project_id
      project.id
    end

    def in_progress
      object.in_progress?
    end

    def can_view_enrollment
      current_permission?(permission: :can_view_enrollment_details, entity: object)
    end

    def project
      load_ar_association(object, :project)
    end
  end
end
