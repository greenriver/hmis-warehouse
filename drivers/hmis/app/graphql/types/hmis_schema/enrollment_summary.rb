module Types
  class HmisSchema::EnrollmentSummary < Types::BaseObject
    field :id, ID, null: false
    field :entry_date, GraphQL::Types::ISO8601Date, null: false
    field :project_name, String, null: false
    field :project_type, Types::HmisSchema::Enums::ProjectType, null: false
    field :project_id, String, null: false
    field :move_in_date, GraphQL::Types::ISO8601Date, null: true
    field :in_progress, Boolean, null: false
    field :can_view_enrollment, Boolean, null: false
    field :primary_key, ID, null: true

    def id
      object.enrollment_id
    end

    def project_name
      project.project_name
    end

    def project_type
      project.project_type
    end

    def project_id
      project.project_id
    end

    def in_progress
      object.in_progress?
    end

    def can_view_enrollment
      current_user.can_view_enrollment_details_for?(object)
    end

    def primary_key
      can_view_enrollment ? object.id : nil
    end

    def project
      @project ||= object.project
    end
  end
end
