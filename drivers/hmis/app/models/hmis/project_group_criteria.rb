###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# rename to ProjectFilter  class, as a generalized tool for creating a list of projects from criteria?
module Hmis
  class ProjectGroupCriteria < ::ModelForm
    include ApplicationHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Context

    # Define attributes with defaults
    attribute :project_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    attribute :project_type_numbers, Array, default: []
    attribute :hmis_participation_status, Integer, default: nil
    attribute :project_status, String, default: 'all'

    # Allowed attributes for validation and updates
    ALLOWED_ATTRIBUTES = [
      :project_ids,
      :organization_ids,
      :data_source_ids,
      :project_type_numbers,
      :hmis_participation_status,
      :project_status,
    ].freeze

    # Validations
    validates :hmis_participation_status, inclusion: { in: [0, 1, 2], allow_nil: true, message: 'must be 0, 1, or 2' }
    validates :project_status, inclusion: { in: ['open', 'closed', 'all'], allow_nil: true, message: "must be 'open', 'closed', or 'all'" }

    # Initialize with a hash or JSON blob
    def initialize(input = {})
      super()
      update(input)
    end

    # Update attributes dynamically
    def update(attributes)
      attributes = parse_input(attributes)
      Rails.logger.info(">>> attributes #{attributes}")
      # {:project_ids=>["", "88"], :data_source_ids=>[""], :organization_ids=>[""], :project_type_numbers=>[""]}
      attributes.each do |key, value|
        cleaned_value = value.is_a?(Array) ? value.reject(&:blank?) : value
        send("#{key}=", cleaned_value) if ALLOWED_ATTRIBUTES.include?(key)
      end
      self
    end

    # Convert to hash
    def to_h
      ALLOWED_ATTRIBUTES.index_with { |attr| send(attr) }
    end

    # Convert to JSON
    def to_json(*_args)
      to_h.to_json
    end

    # Check if the object is persisted
    def persisted?
      false
    end

    # Effective project IDs based on criteria
    def effective_project_ids
      ids = []
      ids << Hmis::Hud::Project.hmis.where(id: project_ids).pluck(:id) if project_ids.any?
      ids << Hmis::Hud::Organization.hmis.joins(:projects).where(id: organization_ids).pluck(:id) if organization_ids.any?
      ids << GrdaWarehouse::DataSource.hmis.joins(:projects).where(id: data_source_ids).pluck(:id) if data_source_ids.any?
      ids << Hmis::Hud::Project.hmis.where(project_type: project_type_numbers).pluck(:id) if project_type_numbers.any?
      ids.flatten.uniq
    end

    def self.available_project_type_numbers
      ::HudUtility2024.project_types.invert
    end

    # Describe criteria as HTML
    def describe_criteria_as_html
      return ''.html_safe if project_ids.blank? && organization_ids.blank? && data_source_ids.blank? && project_type_numbers.blank?

      criteria = []

      # Add Projects
      if project_ids.any?
        project_names = Hmis::Hud::Project.hmis.where(id: project_ids).pluck(:ProjectName)
        criteria << { label: 'Projects', values: project_names }
      end

      # Add Organizations
      if organization_ids.any?
        organization_names = Hmis::Hud::Organization.hmis.where(id: organization_ids).pluck(:OrganizationName)
        criteria << { label: 'Organizations', values: organization_names }
      end

      # Add Data Sources
      if data_source_ids.any?
        data_source_names = GrdaWarehouse::DataSource.hmis.where(id: data_source_ids).pluck(:name)
        criteria << { label: 'Data Sources', values: data_source_names }
      end

      # Add Project Types
      criteria << { label: 'Project Types', values: project_type_names } if project_type_numbers.any?

      # Generate HTML
      criteria_inner = criteria.map do |criterion|
        wrapper_classes = ['report-parameters__parameter', 'd-flex']
        label_text = "#{criterion[:label]}:"
        values = criterion[:values]

        # Limit the number of displayed values
        if values.is_a?(Array) && values.size > 5
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

    # Get project type names
    def project_type_names
      project_type_numbers.uniq.map { |pt| HudUtility2024.project_type(pt.to_i) }
    end

    private

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
