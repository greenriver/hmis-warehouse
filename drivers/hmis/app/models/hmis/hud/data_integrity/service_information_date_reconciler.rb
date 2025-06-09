# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Set service information date (new in 2026). It's not a nullable field so populate it with fa_start_date
#
class Hmis::Hud::DataIntegrity::ServiceInformationDateReconciler < Hmis::Hud::DataIntegrity::BaseReconciler
  # @param [Hmis::Hud::Service] record
  def call(record)
    messages = []

    # SSVF FA uses form input. Other services use start date s information date
    record.service_information_date = record.fa_start_date if record.record_type != RecordType::SSVF_FINANCIAL_ASSISTANCE
    messages << 'information_date should be present' if record.information_date.nil?

    format_messages(record, messages)
  end
end
