###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ProjectCeConfig < Hmis::ProjectConfig
  def config_type = 'COORDINATED_ENTRY'

  SUPPORTS_WAITLIST_REFERRALS = 'supports_waitlist_referrals'
  RECEIVES_DIRECT_REFERRALS = 'receives_direct_referrals'
  RECEIVES_DIRECT_REFERRALS_FROM = 'receives_direct_referrals_from'

  validate :either_direct_or_waitlist_referrals

  # "waitlist referrals" are referrals initiated from within a unit's waitlist.
  def supports_waitlist_referrals?
    return true unless options # True by default if this project config does not have config_options (for backwards compatibility).

    options[SUPPORTS_WAITLIST_REFERRALS] || false
  end

  def supports_waitlist_referrals=(value)
    set_config_option(SUPPORTS_WAITLIST_REFERRALS, value)
  end

  # "direct" referrals are referrals initiated by a sending project.
  def receives_direct_referrals?
    return false unless options # False by default, needs to be enabled explicitly in the config_options

    options[RECEIVES_DIRECT_REFERRALS] || false
  end

  def receives_direct_referrals=(value)
    set_config_option(RECEIVES_DIRECT_REFERRALS, value)
  end

  # Optionally, a project can specify which specific projects it receives direct referrals from.
  # If this is not specified, but `receives_direct_referrals` is true, then the project receives direct referrals from all projects (that have ProjectSendsDirectCeReferralsConfig).
  def receives_direct_referrals_from
    return nil unless options

    options[RECEIVES_DIRECT_REFERRALS_FROM]
  end

  def receives_direct_referrals_from=(value)
    set_config_option(RECEIVES_DIRECT_REFERRALS_FROM, value)
  end

  private

  def either_direct_or_waitlist_referrals
    return unless options
    return if supports_waitlist_referrals? || receives_direct_referrals?

    errors.add(:base, 'Project must either receive direct referrals or support waitlist referrals, or both')
  end
end
