###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Accessor API for CE configuration via AppConfigProperty.
#
# CE settings are deployment-wide global keys (not scoped by HMIS data source).
# Per–data-source HMIS app config properties may be introduced later.
#
# Properties are not seeded automatically; they can be set manually per environment
# through the Admin App Config Properties UI or a direct database insert.
#
# Keys (value type — semantics):
# - hmis_ce/enabled (Boolean) — Feature flag for CE processing.
# - hmis_ce/eligibility_lookback_months (Integer 0–12) — 0 = open enrollments on
#   the evaluation date only. N > 0 = enrollments overlapping
#   [current_date - N months, current_date]. Defaults to 0 when unset.
# - hmis_ce/eligibility_project_group_id (Integer, Hmis::ProjectGroup id) — Limits
#   enrollment-field resolution to enrollments at projects in the group (via
#   Hmis::ProjectGroup#effective_project_ids). Blank/unset = all projects.
# - hmis_ce/bulk_void_enabled (Boolean) — Feature flag for community-specific
#   "bulk void" mutation.
module Hmis::Ce
  class Configuration
    class Misconfiguration < StandardError; end

    ELIGIBILITY_LOOKBACK_RANGE = (0..12)

    # feature flag for CE
    def enabled?
      !!value_for(:enabled)
    end

    # Months of enrollment history to include when resolving enrollment-scoped CE match fields.
    #
    # NOTE: When this value changes, Candidate Pools must be reprocessed. Currently we
    # rely on nightly processing to update the Candidate Pools, rather than a trigger on change.
    #
    # @return [Integer]
    def eligibility_lookback_months
      raw = value_for(:eligibility_lookback_months)
      return 0 if raw.nil? # Default to 0 if not set, which means only currently open enrollments are considered

      months = parse_integer(raw)
      raise Misconfiguration, "hmis_ce/eligibility_lookback_months must be between 0 and 12, got #{months.inspect}" unless ELIGIBILITY_LOOKBACK_RANGE.cover?(months)

      months
    end

    # HMIS ProjectGroup to use when resolving enrollment-related CE match fields.
    #
    # NOTE: When this value changes, Candidate Pools must be reprocessed. Currently we
    # rely on nightly processing to update the Candidate Pools, rather than a trigger on change.
    #
    # @return [Hmis::ProjectGroup, nil]
    def eligibility_project_group
      raw = value_for(:eligibility_project_group_id)
      return nil if raw.blank? # Default to nil if not set, which means all projects are considered

      id = parse_integer(raw)

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

    def parse_integer(raw)
      Integer(raw)
    rescue ArgumentError, TypeError
      raise Misconfiguration, "expected an integer, got #{raw.inspect}"
    end
  end
end
