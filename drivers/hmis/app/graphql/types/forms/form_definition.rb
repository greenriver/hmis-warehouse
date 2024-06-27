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
    field :status, HmisSchema::Enums::FormStatus, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false, method: :updated_at
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :updated_by, Types::Application::User, null: true
    field :project_matches, [Types::Forms::ProjectMatch], null: false
    form_rules_field :form_rules, method: :instances

    # Filtering is implemented within this resolver rather than a separate concern. This
    # gives us convenient to access the lazy batch loader for records (funder, orgs) that
    # we might need to apply filter. Probably the filtering should get moved to it's own
    # class down the road
    def definition
      Hmis::Form::DefinitionItemFilter.perform(
        definition: object.definition,
        project: project,
        project_funders: project_funders,
        active_date: active_date,
      )
    end

    def project_matches
      # Returns one match per project that this form applies to. (See InstanceProjectMatch for match ranking logic.)
      # This DOES still return a match for a project if the match is overridden by a more specific rule on another form.
      # For example, if:
      # - Intake form A has a rule that specifies that it's used for all projects
      # - Intake form B has a rule that specifies that it's used for all Emergency Shelter projects
      # - Intake form C has a rule that specifies that it's used for Project X, an ES project
      # ...then forms A and B would still return a match for Project X.
      object.instances.
        active.
        map(&:project_matches).
        flatten.
        sort_by(&:rank).
        reverse. # lower rank means a better match
        map { |match| [match.project.id, match] }. # per project ID, the later added (lower ranked) matches overwrite the earlier ones
        to_h.values
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

    def updated_by
      load_last_user_from_versions(object)
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
