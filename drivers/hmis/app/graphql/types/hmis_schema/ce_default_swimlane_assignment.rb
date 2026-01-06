###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeDefaultSwimlaneAssignment < Types::BaseObject
    field :id, ID, null: false
    field :user, Application::User, null: false
    field :swimlane, HmisSchema::CeSwimlane, null: false

    # Polymorphic owner - only one will be non-null. If all are null, this is a global default (owned by data source)
    field :project, HmisSchema::Project, null: true
    field :organization, HmisSchema::Organization, null: true
    field :unit_group, HmisSchema::UnitGroup, null: true

    field :global, GraphQL::Types::Boolean, null: false

    def user
      load_ar_association(object, :user)
    end

    def swimlane
      load_ar_association(object, :swimlane)
    end

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

    def global
      object.owner_type == 'GrdaWarehouse::DataSource'
    end
  end
end
