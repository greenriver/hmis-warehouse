###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::PickListOption < Types::BaseObject
    field :code, String, 'Code for the option', null: false
    field :label, String, 'Label for the option', null: true
    field :secondary_label, String, 'Secondary label, such as project type or CoC code', null: true
    field :group_code, String, 'Code for group that option belongs to, if grouped', null: true
    field :group_label, String, 'Label for group that option belongs to, if grouped', null: true
    field :initial_selected, Boolean, 'Whether option is selected by default', null: true

    def self.options_for_type(pick_list_type, user:)
      case pick_list_type
      when 'COC'
        ::HUD.cocs_in_state(ENV['RELEVANT_COC_STATE']).sort.map do |code, name|
          { code: code, label: name, secondary_label: code }
        end

      when 'PRIOR_LIVING_SITUATION'
        living_situation_options(as: :prior)

      when 'CURRENT_LIVING_SITUATION'
        living_situation_options(as: :current)

      when 'PROJECT'
        Hmis::Hud::Project.editable_by(user).
          joins(:organization).
          sort_by_option(:organization_and_name).
          map do |project|
          {
            code: project.id,
            label: project.project_name,
            secondary_label: HUD.project_type_brief(project.project_type),
            group_label: project.organization.organization_name,
            group_code: project.organization.id,
          }
        end

      when 'ORGANIZATION'
        Hmis::Hud::Organization.editable_by(user).
          sort_by_option(:name).
          map do |organization|
          {
            code: organization.id,
            label: organization.organization_name,
          }
        end
      end
    end

    def self.living_situation_options(as:)
      to_option = ->(group_code, group_label) {
        proc do |id|
          {
            code: id,
            label: ::HUD.living_situation(id),
            group_code: group_code,
            group_label: group_label,
          }
        end
      }

      homeless = ::HUD.homeless_situations(as: as).map(&to_option.call('HOMELESS', 'Homeless'))
      institutional = ::HUD.institutional_situations(as: as).map(&to_option.call('INSTITUTIONAL', 'Institutional'))
      temporary = ::HUD.temporary_and_permanent_housing_situations(as: as).map(&to_option.call('TEMPORARY_PERMANENT_OTHER', 'Temporary or Permanent'))
      missing_reasons = ::HUD.other_situations(as: as).map(&to_option.call('MISSING', 'Other'))

      homeless + institutional + temporary + missing_reasons
    end
  end
end
