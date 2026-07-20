###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# accessor API for CE configuration
#
# Eligibility scope keys (lookback months, project group) are deployment-wide global
# settings stored in AppConfigProperty. Per–data-source HMIS configuration is deferred.
#
# TODO: When hmis_ce/eligibility_lookback_months or hmis_ce/eligibility_project_group_id
# changes, mark CE candidate pools/clients dirty for reprocessing (see README_FOR_CE_PROCESSING.md).
module Hmis::Ce
  class Configuration
    class Misconfiguration < StandardError; end

    ELIGIBILITY_LOOKBACK_RANGE = (0..12)

    # feature flag for CE
    def enabled?
      !!value_for(:enabled)
    end

    # Months of enrollment history to include when resolving enrollment-scoped CE match fields.
    # 0 = open enrollments on current_date only.
    def eligibility_lookback_months
      raw = value_for(:eligibility_lookback_months)
      return 0 if raw.nil?

      months = Integer(raw)
      raise Misconfiguration, "hmis_ce/eligibility_lookback_months must be between 0 and 12, got #{months.inspect}" unless ELIGIBILITY_LOOKBACK_RANGE.cover?(months)

      months
    rescue ArgumentError, TypeError
      raise Misconfiguration, "hmis_ce/eligibility_lookback_months must be an integer between 0 and 12, got #{raw.inspect}"
    end

    # Project group ID to use for eligibility from enrollment-related CE match fields.
    # If specified, enrollment-related fields are only resolved for enrollments at projects in the group.
    def eligibility_project_group_id
      raw = value_for(:eligibility_project_group_id)
      return nil if raw.blank?

      Integer(raw)
    rescue ArgumentError, TypeError
      raise Misconfiguration, "hmis_ce/eligibility_project_group_id must be an integer, got #{raw.inspect}"
    end

    # @return [Hmis::ProjectGroup, nil]
    def eligibility_project_group
      id = eligibility_project_group_id
      return nil if id.blank?

      group = Hmis::ProjectGroup.with_deleted.find_by(id: id)
      raise Misconfiguration, "hmis_ce/eligibility_project_group_id #{id} does not exist" if group.nil?
      raise Misconfiguration, "hmis_ce/eligibility_project_group_id #{id} refers to a deleted project group" if group.deleted?

      group
    end

    def bulk_void_enabled?
      !!value_for(:bulk_void_enabled)
    end

    protected

    # read all configuration values from the db
    PROPERTIES = [
      :enabled,
      :eligibility_lookback_months,
      :eligibility_project_group_id,
      :bulk_void_enabled,
    ].freeze
    def values
      @values ||= AppConfigProperty.
        where(key: PROPERTIES.map { |attr| key_for(attr) }).
        pluck(:key, :value).
        to_h
    end

    def value_for(attr)
      values[key_for(attr)]
    end

    def key_for(attr)
      "hmis_ce/#{attr}"
    end
  end
end
