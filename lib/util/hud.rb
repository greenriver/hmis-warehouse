###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This module provides version-aware access to HUD utility classes and manages
# the transition between different HUD specification versions. It automatically
# selects the appropriate utility class based on environment-specific cutoff dates
# and maintains version consistency within a single request/job/thread context.
#
# The module supports multiple HUD CSV specification versions:
# - 2026: Current specification (default for test/development)
# - 2024: Previous specification (production default until October 1, 2025)
# - legacy: Older specification for legacy code and HUD reports.
#
# @example Basic usage
#   # Get current version utility
#   Hud.util.gender('1') # => "Female"
#
# @example Explicit version
#   # Use specific version
#   legacy_util = Hud.util('legacy')
#   current_util = Hud.util('2026')
#
# @see HudUtility2026
# @see HudUtility2024
# @see HudUtilityLegacy
module Hud
  class Current < ActiveSupport::CurrentAttributes
    attribute :current_fy
  end

  class << self
    # Returns the appropriate HUD utility class for the specified version
    #
    # @param version [String, nil] The HUD CSV version to use. If nil, uses the current version
    #   based on environment and date cutoffs. Valid values: '2026', '2024', 'legacy'
    # @param force_recalculate [Boolean] Whether to force recalculation of the current version
    #   even if one is already pinned for this request/job/thread, this should only be used for testing
    # @return [Class] The HUD utility class (HudUtility2026, HudUtility2024, or HudUtilityLegacy)
    # @raise [RuntimeError] If an unknown version is specified
    # @example
    #   Hud.util('2026') #=> HudUtility2026
    #   Hud.util         #=> Returns current version utility based on environment
    def util(version = nil, force_recalculate: false)
      version ||= current_version(force_recalculate: force_recalculate)

      case version.to_s
      when '2026'
        HudUtility2026
      when '2024'
        HudUtility2024
      when 'legacy'
        HudUtilityLegacy
      else
        raise "Unknown HUD utility version: #{version}"
      end
    end

    # Move to 2026 in production after 2025-10-01
    # Move to 2026 in staging after 2025-09-01
    # Move to 2026 in test and development now
    def current_version(force_recalculate: false)
      # If we've already chosen a version in this request/job/thread, use it
      pinned = Hud::Current.current_fy
      return pinned if pinned && !force_recalculate

      # Update as necessary.  During transition periods, this section may become more complex with additional
      # logic specific to development, testing, and QA environments.
      result = if Rails.env.production?
        # return the previous version before the cutoff
        Date.current < production_cutoff ? '2024' : '2026'
      elsif Rails.env.staging?
        # return the previous version before the cutoff
        Date.current < staging_cutoff ? '2024' : '2026'
      else
        '2026'
      end

      # pin version for this request/job/thread so it stays consistent
      Hud::Current.current_fy = result

      result
    end
    alias_method :hud_csv_version, :current_version

    def production_cutoff
      Date.new(2025, 10, 1)
    end

    def staging_cutoff
      Date.new(2025, 9, 1)
    end
  end
end
