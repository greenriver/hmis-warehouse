###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasFlatProjectAndOrganization
      extend ActiveSupport::Concern

      class_methods do
        def flat_project_and_organization_fields(nullable:, skip_project_type: false)
          field(:project_id, GraphQL::Types::ID, null: nullable)
          field(:project_name, GraphQL::Types::String, null: true)
          field(:project_type, Types::HmisSchema::Enums::ProjectType, null: true) unless skip_project_type
          field(:organization_id, GraphQL::Types::ID, null: nullable)
          field(:organization_name, GraphQL::Types::String, null: true)

          define_method(:project_id) { project&.id }
          define_method(:project_name) { project&.project_name }
          define_method(:project_type) { project&.project_type } unless skip_project_type
          define_method(:organization_id) { organization&.id }
          define_method(:organization_name) { organization&.organization_name }

          define_method(:project) do
            load_ar_association(object, :project)
          end
          define_method(:organization) do
            load_ar_association(object, :organization)
          end
        end
      end
    end
  end
end
