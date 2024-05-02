###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::FormIdentifier < Types::BaseObject
    skip_activity_log
    description 'FormIdentifier'

    available_filter_options do
      arg :search_term, String
      # ADD: role
      # ADD: status
    end

    # TODO: add summary information so the UI can resolve top-level detail such as 'active in 15 projects'

    field :id, String, null: false
    field :identifier, String, null: false
    field :role, Types::Forms::Enums::FormRole, null: false
    field :title, String, null: false

    field :current_version, Types::Forms::FormDefinition, null: false
    field :draft, Types::Forms::FormDefinition, null: true
    field :retired_versions, Types::Forms::FormDefinition.page_type, null: false

    def id
      object.id
    end

    def current_version
      object
    end

    def draft
      Hmis::Form::Definition.find_by(identifier: object.identifier, status: 'draft')
    end

    def retired_versions
      Hmis::Form::Definition.where(identifier: object.identifier, status: 'retired').order(version: :desc)
    end
  end
end
