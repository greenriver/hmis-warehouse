###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class ProjectGroupCriteria < OpenStruct
    # include ActiveModel::Model
    # include ActiveModel::Attributes
    # include ActiveModel::Validations

    # Define attributes with their types
    # attribute :coc_codes, Array
    # attribute :data_source_ids, Array
    # attribute :organization_ids, Array
    # attribute :project_ids, Array
    # attribute :funder_ids, Array
    # attribute :project_type_numbers, Array
    # attribute :project_group_ids, Array
    # attribute :hmis_participation_status, Array
    # attribute :ce_participation_access_point, :boolean
    # attribute :project_status, :string

    # Validations
    # validates :hmis_participation_status, inclusion: { in: [0, 1, 2], allow_nil: true, message: 'must be 0, 1, or 2' }
    # validates :project_status, inclusion: { in: ['open', 'closed', 'all'], allow_nil: true, message: "must be 'open', 'closed', or 'all'" }
    # validate :validate_array_of_integers

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

    # Initialize with a JSON blob
    def initialize(json_blob = '{}')
      parsed_data = JSON.parse(json_blob, symbolize_names: true)
      validate_keys!(parsed_data)
      super(parsed_data)
    end

    # Optional: Add custom methods for specific fields if needed
    def open_projects_only?
      project_status == 'open'
    end

    def closed_projects_only?
      project_status == 'closed'
    end

    private

    # Ensure only allowed keys are present in the JSON blob
    def validate_keys!(attributes)
      # invalid_keys = attributes.keys - ALLOWED_ATTRIBUTES
      # raise ArgumentError, "Invalid attributes: #{invalid_keys.join(', ')}" if invalid_keys.any?
    end

    # Validate that specific attributes are arrays of integers
    def validate_array_of_integers
      [
        :data_source_ids,
        :organization_ids,
        :project_ids,
        :funder_ids,
        :project_type_numbers,
        :project_group_ids,
      ].each do |attr|
        value = send(attr)
        next unless value.present?

        errors.add(attr, 'must be an array of integers') unless value.is_a?(Array) && value.all? { |v| v.is_a?(Integer) }
      end
    end
  end
end
