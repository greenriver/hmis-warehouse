###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Organization < Types::BaseObject
    include Types::HmisSchema::HasProjects
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata
    include Types::HmisSchema::HasCeMatchRules

    def self.configuration
      Hmis::Hud::Organization.hmis_configuration(version: '2024')
    end

    available_filter_options do
      arg :search_term, String
      arg :ce_waitlists_enabled, Boolean
    end

    field :id, ID, null: false
    field :hud_id, ID, null: false, method: :organization_id
    field :organization_name, String, null: false
    field :ce_waitlist_unit_group_count, Integer, null: false, description: 'Number of unit groups under this organization in projects that have waitlist referrals enabled.'
    projects_field :projects, filter_args: { omit: [:organization, :ce_enabled], type_name: 'ProjectsForEnrollment' }
    field :victim_service_provider, HmisSchema::Enums::Hud::NoYesMissing, null: false, default_value: 99
    field :description, String, null: true
    field :contact_information, String, null: true
    custom_data_elements_field
    access_field do
      define_method(:policy) { @policy ||= policy_for(object, policy_type: :hmis_organization) }

      bool_field(:can_delete_organization) { policy.can_delete? }
      bool_field(:can_edit_organization) { policy.can_edit? }
      bool_field(:can_create_projects) { policy.can_create_project? }
    end

    def projects(**args)
      resolve_projects(object.projects, **args)
    end

    def ce_waitlist_unit_group_count
      # Doesn't need to be separately authorized with ce_match_rule_policy.can_manage?
      # because the unit group count isn't sensitive. If you can see the org, you can request this field
      load_ar_association(object, :ce_waitlist_unit_groups).size
    end

    def self.organizations(scope = Hmis::Hud::Organization.all, user:)
      scope.viewable_by(user)
    end

    private

    # Used by the HasCeMatchRules concern
    def ce_match_rule_group_owners
      [object.data_source, object]
    end
  end
end
