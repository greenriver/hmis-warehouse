# frozen_string_literal: true

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::FormDefinition < Types::BaseObject
    skip_activity_log
    description 'FormDefinition'

    include Types::Admin::HasFormRules

    available_filter_options do
      arg :search_term, String
      # ADD: role
      # ADD: status
    end

    field :id, ID, null: false
    field :cache_key, ID, null: false
    field :identifier, String, null: false
    # "role" describes the function of this form within the application, such as editing a project. Roles are unique
    # except for custom-assessments
    field :role, Types::Forms::Enums::FormRole, null: false
    field :title, String, null: false
    field :definition, Forms::FormDefinitionJson, null: false
    field :raw_definition, JsonObject, null: false
    field :system, Boolean, null: false
    form_rules_field :form_rules, method: :instances

    # Filtering is implemented within this resolver rather than a separate concern. This
    # gives us convenient to access the lazy batch loader for records (funder, orgs) that
    # we might need to apply filter. Probably the filtering should get moved to it's own
    # class down the road
    def definition
      Hmis::Form::DefinitionItemGraphqlAdapter.perform(
        definition: object.definition,
        project: project,
        project_funders: project_funders,
        active_date: active_date,
      )
    end

    def raw_definition
      object.definition
    end

    def cache_key
      [object.id, project&.id, active_date&.strftime('%Y-%m-%d')].join('|')
    end

    def system
      load_ar_association(object, :instances).any?(&:system)
    end

    protected

    def project
      object.filter_context&.fetch(:project, nil)
    end

    # Context can optionally include an "active date", so that funder-based rules
    # only consider funders that are active on the specified date.
    def active_date
      object.filter_context&.fetch(:active_date, nil) || Date.current
    end

    def project_funders
      return [] unless project.present?

      funders = load_ar_association(project, :funders)
      funders.to_a.select { |f| f.active_on?(active_date) }
    end
  end
end
