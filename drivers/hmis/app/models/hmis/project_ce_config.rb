###
# Copyright Green River Data Group, Inc.
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
  before_save :clear_referral_sources_unless_receiving
  after_save :rebuild_candidate_pool, if: :supports_waitlist_referrals?

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

  # Stored as Rails project primary keys, because receives_direct_ce_referrals_from? compares with
  # include?(source_project.id). A GraphQL [ID!] argument arrives as strings, and storing those
  # would make enforcement silently reject every sender, so cast here rather than at a single call
  # site. Ids that are not numeric are dropped rather than coerced, since String#to_i would turn
  # them into project 0 and quietly make the allowlist non-blank.
  def receives_direct_referrals_from=(value)
    ids = Array.wrap(value).compact_blank.filter_map { |id| Integer(id, exception: false) }
    if ids.empty?
      unset_config_option(RECEIVES_DIRECT_REFERRALS_FROM)
    else
      set_config_option(RECEIVES_DIRECT_REFERRALS_FROM, ids)
    end
  end

  private

  def either_direct_or_waitlist_referrals
    return unless options
    return if supports_waitlist_referrals? || receives_direct_referrals?

    errors.add(:base, 'Project must either receive direct referrals or support waitlist referrals, or both')
  end

  # An allowlist of senders is meaningless when the project does not receive direct referrals at
  # all, and leaving a stale one behind means it comes back to life the moment the flag is
  # re-enabled. Done in the model so it holds for the admin form, the console, and the CSV importer
  # alike; the importer can write an allowlist on a waitlist-only config, which this now clears.
  def clear_referral_sources_unless_receiving
    return if receives_direct_referrals?
    return if receives_direct_referrals_from.nil?

    self.receives_direct_referrals_from = nil
  end

  # If Config was saved and it is marked as supporting waitlist referrals, rebuild all candidate pools
  # because there may be additional projects that now need Candidate Pools built.
  def rebuild_candidate_pool
    Hmis::Ce::Match::CandidatePool.lock_for_maintenance! do
      Hmis::Ce::Match::CandidatePoolBuilder.call
    end
  end
end
