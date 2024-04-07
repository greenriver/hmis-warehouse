###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Application::EnrollmentAccessSummary < Types::BaseObject
    # maps to Hmis::EnrollmentAccessSummary
    graphql_name 'EnrollmentAccessSummary'
    field :id, ID, null: false
    field :last_accessed_at, GraphQL::Types::ISO8601DateTime, null: false

    # The project/enrollment may be marked as deleted. Expose only name and ID since deleted objects may not work with
    # our resolvers. Project and client are nullable since associated records could be completely missing
    field :enrollment_id, ID, null: false

    field :client_name, String, null: true
    field :client_id, ID, null: true

    field :project_id, ID, null: true
    field :project_name, String, null: true

    def project_id
      project&.id
    end

    def project_name
      project&.project_name
    end

    def client_id
      client&.id
    end

    def client_name
      # not checking for name permission access, because can_audit_users is required here
      client&.brief_name
    end

    available_filter_options do
      arg :search_term, String
      arg :project, [ID]
      arg :on_or_after, GraphQL::Types::ISO8601Date
    end

    protected

    def enrollment
      load_ar_association(object, :enrollment, scope: Hmis::Hud::Enrollment.with_deleted)
    end

    def project
      load_ar_association(object, :project, scope: Hmis::Hud::Project.with_deleted)
    end

    def client
      load_ar_association(enrollment, :client, scope: Hmis::Hud::Client.with_deleted) if enrollment
    end
  end
end
