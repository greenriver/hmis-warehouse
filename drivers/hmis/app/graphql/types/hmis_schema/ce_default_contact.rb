###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeDefaultContact < Types::BaseObject
    # underlying object is a Hmis::Ce::DefaultSwimlaneAssignment

    field :id, ID, null: false
    field :user, Application::User, null: false
    field :swimlane, HmisSchema::CeSwimlane, null: false

    # Polymorphic owner - only one will be non-null. If all are null, this is a global default (owned by data source)
    field :project_id, ID, null: true
    field :project_name, String, null: true
    field :organization_id, ID, null: true
    field :organization_name, String, null: false
    field :unit_group_id, ID, null: true
    field :unit_group_name, String, null: false

    field :global, GraphQL::Types::Boolean, null: false

    def user
      load_ar_association(object, :user)
    end

    def swimlane
      load_ar_association(object, :swimlane)
    end

    def global
      object.owner_type == 'GrdaWarehouse::DataSource'
    end

    def project_id
      project&.id
    end

    def project_name
      project&.name
    end

    def organization_id
      organization&.id
    end

    def organization_name
      organization&.name
    end

    def unit_group_id
      unit_group&.id
    end

    def unit_group_name
      unit_group&.name
    end

    private

    def project
      return nil unless object.owner_type == 'Hmis::Hud::Project'

      load_ar_association(object, :owner)
    end

    def organization
      return nil unless object.owner_type == 'Hmis::Hud::Organization'

      load_ar_association(object, :owner)
    end

    def unit_group
      return nil unless object.owner_type == 'Hmis::UnitGroup'

      load_ar_association(object, :owner)
    end
  end
end
