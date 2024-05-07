###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::FormIdentifier < Types::BaseObject
    skip_activity_log
    description 'Type representing one form Identifier, which collects all versioned FormDefinitions for the same identifier'

    # object is a Hmis::Form::Definition, but this schema type is a little funny because it doesn't
    # correspond to ONE FormDefinition -- it corresponds to a form _identifier_, such as `spdat`, which
    # can have published, draft, and retired versions. This is to match the frontend mental model,
    # where we want one row per identifier (not one row per version) in the forms table.

    available_filter_options do
      arg :search_term, String
      # ADD: role
      # ADD: status
    end

    field :id, String, null: false
    field :identifier, String, null: false

    field :published, Types::Forms::FormDefinition, null: true
    field :draft, Types::Forms::FormDefinition, null: true
    field :all_versions, Types::Forms::FormDefinition.page_type, null: false
    field :display_version, Types::Forms::FormDefinition, null: false

    def id
      # Cache by identifier, not underlying object id, because ids change over time with new versions
      object.identifier
    end

    def published
      load_ar_association(object, :published_version)
    end

    def draft
      load_ar_association(object, :draft_version)
    end

    def all_versions
      load_ar_association(object, :all_versions)
    end

    def display_version
      # This is a helper for the frontend to display info like the form title, role, etc.
      # Unlike the published and draft versions, it can't be nil.
      # If there exists a published version corresponding to this identifier, use it; otherwise, return the latest
      published || all_versions.first
    end
  end
end
