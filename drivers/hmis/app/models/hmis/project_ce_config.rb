###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ProjectCeConfig < Hmis::ProjectConfig
  def config_type = 'COORDINATED_ENTRY'

  SUPPORTS_WAITLIST_REFERRALS = 'supports_waitlist_referrals'
  ACCEPTS_DIRECT_REFERRALS = 'accepts_direct_referrals'
  ACCEPTS_DIRECT_REFERRALS_FROM = 'accepts_direct_referrals_from'

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
  def accepts_direct_referrals?
    return false unless options # False by default, needs to be enabled explicitly in the config_options

    options[ACCEPTS_DIRECT_REFERRALS] || false
  end

  def accepts_direct_referrals=(value)
    set_config_option(ACCEPTS_DIRECT_REFERRALS, value)
  end

  # Optionally, a project can specify which specific projects it accepts direct referrals from.
  # If this is not specified, but `accepts_direct_referrals` is true, then the project accepts direct referrals from all projects (that have ProjectSendsDirectCeReferralsConfig).
  def accepts_direct_referrals_from
    return nil unless options

    options[ACCEPTS_DIRECT_REFERRALS_FROM]
  end

  def accepts_direct_referrals_from=(value)
    set_config_option(ACCEPTS_DIRECT_REFERRALS_FROM, value)
  end

  private

  def either_direct_or_waitlist_referrals
    return unless options
    return if supports_waitlist_referrals || accepts_direct_referrals

    errors.add(:base, 'Project must either accept direct referrals or support waitlist referrals, or both')
  end
end
