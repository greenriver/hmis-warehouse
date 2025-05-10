###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class ProjectGroupCriteria
    include ::Hmis::Concerns::HmisArelHelper
    include ActiveModel::Model
    include ActiveModel::Validations

    # Define attributes
    attr_accessor :coc_codes, :data_source_ids, :organization_ids, :project_ids,
                  :funder_ids, :project_type_numbers, :project_group_ids,
                  :hmis_participation_status, :ce_participation_access_point, :project_status

    # Allowed attributes for validation
    ALLOWED_ATTRIBUTES = [
      :coc_codes,
      :data_source_ids,
      :organization_ids,
      :project_ids,
      :funder_ids,
      :project_type_numbers,
      :project_group_ids,
      :hmis_participation_status,
      :ce_participation_access_point,
      :project_status,
    ].freeze

    FILTER_ATTRIBUTES = [
      # coc_codes
      :data_source_ids,
      :organization_ids,
      :project_ids,
      :funder_ids,
      :project_type_numbers,
      # project_group_ids
      # hmis_participation_status
      # ce_participation_access_point
      # project_status
    ].freeze

    # Validations
    validates :hmis_participation_status, inclusion: { in: [0, 1, 2], allow_nil: true, message: 'must be 0, 1, or 2' }
    validates :project_status, inclusion: { in: ['open', 'closed', 'all'], allow_nil: true, message: "must be 'open', 'closed', or 'all'" }
    validate :validate_array_attributes

    # Initialize with a hash or JSON blob
    def initialize(input = {})
      attributes = parse_input(input)
      attributes.each do |key, value|
        send("#{key}=", value) if ALLOWED_ATTRIBUTES.include?(key)
      end

      # Ensure all attributes are initialized
      ALLOWED_ATTRIBUTES.each do |attr|
        send("#{attr}=", send(attr) || default_value_for(attr))
      end
    end

    # Convert the object to a hash
    def to_h
      ALLOWED_ATTRIBUTES.index_with { |attr| send(attr) }
    end

    # Convert the object to JSON
    def to_json(*_args)
      to_h.to_json
    end

    # Mark the object as non-persisted (required by Rails forms)
    def persisted?
      false
    end

    # Provide a unique key for the form (optional, but useful for nested forms)
    def to_key
      nil
    end

    # Filter class is used for populating pick-lists in the form
    def filter
      @filter ||= begin
        options = to_h.slice(*FILTER_ATTRIBUTES)
        ::Filters::FilterBase.new(user_id: User.setup_system_user.id).set_from_params(options)
      end
    end

    def effective_project_ids
      ids = []
      ids << Hmis::Hud::Project.hmis.where(id: project_ids.compact_blank).pluck(:id) if project_ids.compact_blank.any?
      ids << Hmis::Hud::Organization.hmis.joins(:projects).where(id: organization_ids.compact_blank).pluck(p_t[:id]) if organization_ids.compact_blank.any?
      ids << GrdaWarehouse::DataSource.hmis.joins(:projects).where(id: data_source_ids.compact_blank).pluck(p_t[:id]) if data_source_ids.compact_blank.any?
      ids << Hmis::Hud::Project.hmis.where(project_type: project_type_numbers.compact_blank).pluck(:id) if project_type_numbers.compact_blank.any?
      ids.flatten.uniq
    end

    def describe_criteria_as_html
      return '' if project_ids.blank? && organization_ids.blank? && data_source_ids.blank? && project_type_numbers.blank?

      criteria = []
      criteria << "Projects: #{Hmis::Hud::Project.hmis.where(id: project_ids.compact_blank).pluck(:ProjectName).join(', ')}" if project_ids.compact_blank.any?
      criteria << "Organizations: #{Hmis::Hud::Organization.hmis.where(id: organization_ids.compact_blank).pluck(:OrganizationName).join(', ')}" if organization_ids.compact_blank.any?
      criteria << "Data Sources: #{GrdaWarehouse::DataSource.hmis.where(id: data_source_ids.compact_blank).pluck(:name).join(', ')}" if data_source_ids.compact_blank.any?
      criteria << "Project Types: #{project_type_names.join(', ')}" if project_type_names.any?

      criteria.join('<br>').html_safe
    end

    def project_type_names
      project_type_numbers.compact_blank.uniq.map { |pt| HudUtility2024.project_type(pt.to_i) }
    end

    private

    # Parse input as either JSON or a hash
    def parse_input(input)
      return [] if input.nil? || input.empty?

      case input
      when String
        JSON.parse(input, symbolize_names: true)
      when Hash
        input.deep_symbolize_keys
      else
        raise ArgumentError, 'Input must be a JSON string or a Hash'
      end
    end

    # Default values for attributes
    def default_value_for(attr)
      case attr
      when :coc_codes, :data_source_ids, :organization_ids, :project_ids,
           :funder_ids, :project_type_numbers, :project_group_ids, :hmis_participation_status
        []
      when :ce_participation_access_point
        false
      when :project_status
        'all'
      end
    end

    # Validate that specific attributes are arrays
    def validate_array_attributes
      [
        :coc_codes,
        :data_source_ids,
        :organization_ids,
        :project_ids,
        :funder_ids,
        :project_type_numbers,
        :project_group_ids,
        :hmis_participation_status,
      ].each do |attr|
        value = send(attr)
        errors.add(attr, 'must be an array') unless value.is_a?(Array)
      end
    end
  end
end
