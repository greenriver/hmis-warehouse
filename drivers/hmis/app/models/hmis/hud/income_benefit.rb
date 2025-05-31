###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::IncomeBenefit < Hmis::Hud::Base
  self.table_name = :IncomeBenefits
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  include ::HmisStructure::IncomeBenefit
  include ::Hmis::Hud::Concerns::Shared
  include ::Hmis::Hud::Concerns::EnrollmentRelated
  include ::Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  include ::Hmis::Hud::Concerns::FormSubmittable

  belongs_to :client, **hmis_relation(:PersonalID, 'Client')
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates_with Hmis::Hud::Validators::IncomeBenefitValidator

  # income_fields = Hmis::Hud::IncomeBenefit.hmis_structure(version: '2024').grep(/Amount/)
  INCOME_FIELDS = [:EarnedAmount, :UnemploymentAmount, :SSIAmount, :SSDIAmount, :VADisabilityServiceAmount, :VADisabilityNonServiceAmount, :PrivateDisabilityAmount, :WorkersCompAmount, :TANFAmount, :GAAmount, :SocSecRetirementAmount, :PensionAmount, :ChildSupportAmount, :AlimonyAmount, :OtherIncomeAmount].freeze
  def admin_review_and_normalization
    calculated_income = INCOME_FIELDS.filter_map { |field| public_send(field)&.to_i }.sum
    return if calculated_income&.round(2) == total_monthly_income&.round(2)

    handle_normalization_issue("Total monthly income does not match calculated income. Expected #{total_monthly_income} to equal calculated: #{calculated_income} (auto-corrected)")
    self.total_monthly_income = calculated_income
  end

  def handle_normalization_issue(message)
    message = "#{self.class.name}##{id}: #{message}"
    raise message if Rails.env.development?

    Sentry.capture_message(message)
  end
end
