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

    field :published, Types::Forms::FormDefinition, null: true
    field :draft, Types::Forms::FormDefinition, null: true
    field :all_versions, Types::Forms::FormDefinition.page_type, null: false

    def published
      load_ar_association(object, :published_version)
    end

    def draft
      load_ar_association(object, :draft_version)
    end

    def all_versions
      load_ar_association(object, :all_versions)
    end

    def id
      object.identifier
    end

    def title
      published&.title ? published.title : object.title
    end

    def role
      published&.role ? published.role : object.role
    end
  end
end
