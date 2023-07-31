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
      current_user.can_view_enrollment_details_for?(object)
    end

    def project
      if object.in_progress?
        wip = load_ar_association(object, :wip)
        load_ar_association(wip, :project)
      else
        load_ar_association(object, :project)
      end
    end
  end
end
