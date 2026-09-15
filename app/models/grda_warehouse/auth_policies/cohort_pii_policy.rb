###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# PII policy for the cohort grid: name, DOB, photo, and HIV status have always been shown
# to anyone who can see the cohort, so those stay allowed. The full SSN is gated behind the
# viewer's global permission -- the same check ApplicationHelper#ssn applies elsewhere -- and
# a partial (masked) SSN always shows unless the client is separately restricted, which
# GrdaWarehouse::PiiProvider.restrict wraps around this policy.
class GrdaWarehouse::AuthPolicies::CohortPiiPolicy
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def can_view?
    true
  end

  def can_view_name?
    true
  end

  def can_view_photo?
    true
  end

  def can_view_full_dob?
    true
  end

  def can_view_hiv_status?
    true
  end

  def can_view_partial_ssn?
    true
  end

  def can_view_full_ssn?
    user.can_view_full_ssn?
  end
end
