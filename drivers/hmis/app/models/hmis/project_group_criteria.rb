###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class ProjectGroupCriteria < ::ModelForm
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Context
    include ::Hmis::Concerns::HmisArelHelper

    # Source data source for this project filter. ProjectGroupCriteria filter cannot be used across multiple data sources.
    attribute :data_source_id, Integer, default: nil

    # Attributes for filtering
    attribute :project_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :all_projects_in_data_source, Boolean, default: false
    attribute :project_type_numbers, Array, default: []
    # TODO: add more filtering capabilities:
    # attribute :hmis_participation_status, Integer, default: nil
    # attribute :ce_participation_access_point, Boolean, default: nil
    # attribute :funder_ids, Array, default: []
    # attribute :coc_codes, Array, default: []
    # attribute :project_group_ids, Array, default: []
    # attribute :coc_codes, Array, default: []
    # attribute :project_status, String, default: 'all'

    # Allowed attributes for validation and updates
    ALLOWED_ATTRIBUTES = [
      :project_ids,
      :organization_ids,
      :all_projects_in_data_source,
      :project_type_numbers,
      # :hmis_participation_status,
      # :project_status,
    ].freeze

    # Validations
    # validates :hmis_participation_status, inclusion: { in: [0, 1, 2], allow_nil: true, message: 'must be 0, 1, or 2' }
    # validates :project_status, inclusion: { in: ['open', 'closed', 'all'], allow_nil: true, message: "must be 'open', 'closed', or 'all'" }

    # Initialize with a hash or JSON blob
    def initialize(input = {}, data_source_id:)
      super()
      update(input)
      self.data_source_id = data_source_id
    end

    def update(attributes)
      attributes = parse_input(attributes)
      attributes.each do |key, value|
        cleaned_value = value.is_a?(Array) ? value.reject(&:blank?) : value

        raise ArgumentError, "Invalid attribute for ProjectGroupCriteria: #{key}. Allowed attributes are: #{ALLOWED_ATTRIBUTES.join(', ')}" unless ALLOWED_ATTRIBUTES.include?(key)

        send("#{key}=", cleaned_value)
      end
      self
    end

    def to_h
      ALLOWED_ATTRIBUTES.index_with { |attr| send(attr) }
    end

    def to_json(*_args)
      to_h.to_json
    end

    def persisted?
      false
    end

    # Returns a unique list of project IDs that match the criteria defined by this class.
    def effective_project_ids
      ids = []
      ids << project_scope.where(id: project_ids).pluck(:id) if project_ids.any?
      ids << organization_scope.joins(:projects).where(id: organization_ids).pluck(p_t[:id]) if organization_ids.any?
      ids << project_scope.where(project_type: project_type_numbers).pluck(:id) if project_type_numbers.any?
      ids << data_source.projects.pluck(p_t[:id]) if all_projects_in_data_source
      ids.flatten.uniq
    end

    # Describe criteria as HTML
    def describe_criteria_as_html
      return ''.html_safe if project_ids.blank? && organization_ids.blank? && !all_projects_in_data_source && project_type_numbers.blank?

      criteria = []

      # Add Projects
      if project_ids.any?
        project_names = project_scope.where(id: project_ids).pluck(:ProjectName)
        criteria << { label: 'Projects', values: project_names }
      end

      # Add Organizations
      if organization_ids.any?
        organization_names = organization_scope.where(id: organization_ids).pluck(:OrganizationName)
        criteria << { label: 'Organizations', values: organization_names }
      end

      # Add Data Sources
      criteria << { label: 'Include all projects in Data Source', values: ['Yes'] } if all_projects_in_data_source

      # Add Project Types
      if project_type_numbers.any?
        project_type_names = project_type_numbers.uniq.map { |pt| HudUtility2024.project_type(pt.to_i) }
        criteria << { label: 'Project Types', values: project_type_names }
      end

      # Generate HTML. This is based on Filter::FilterBase#describe_criteria_as_html
      criteria_inner = criteria.map do |criterion|
        wrapper_classes = ['report-parameters__parameter', 'd-flex']
        label_text = "#{criterion[:label]}:"
        values = criterion[:values]

        # Limit the number of displayed values
        if values.is_a?(Array) && values.size > 10
          count = values.size
          values = values.first(5)
          values << "#{count - 5} more"
        end

        content_tag(:div, class: wrapper_classes) do
          label = content_tag(:label, label_text, class: 'label label-default parameter-label pl-0')
          value = content_tag(:label, values.to_sentence, class: ['label', 'label-primary', 'parameter-value', 'pl-0', 'mb-0'])
          label.concat(value)
        end
      end.join.html_safe

      content_tag(:div, criteria_inner, class: 'report-parameters-all') # wrap in div for styling
    end

    def self.available_project_type_numbers
      ::HudUtility2024.project_types.invert
    end

    private

    def project_scope
      ::GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id)
    end

    def organization_scope
      ::GrdaWarehouse::Hud::Organization.where(data_source_id: data_source_id)
    end

    def data_source
      ::GrdaWarehouse::DataSource.hmis.find(data_source_id)
    end

    # Parse input as either JSON or a hash
    def parse_input(input)
      case input
      when String
        JSON.parse(input, symbolize_names: true)
      when Hash
        input.deep_symbolize_keys
      else
        {}
      end
    end
  end
end
