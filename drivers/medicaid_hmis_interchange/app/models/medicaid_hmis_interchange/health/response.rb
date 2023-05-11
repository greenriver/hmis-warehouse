###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class Response < ::HealthBase
    belongs_to :submission
    has_many :response_external_ids
    has_many :external_ids, through: :response_external_ids

    COLUMNS = [
      :medicaid_id,
      :homeless_flag,
      :error_code,
      :field,
    ].freeze
    def process_response
      errors.each do |error|
        # If the medicaid ID was flagged by MH, mark it as invalid
        ExternalId.find_by(identifier: error[:medicaid_id])&.update(valid_id: false) if error[:error_code] == '3' && error[:field] == '1'
      end
    end

    def errors
      @errors ||= [].tap do |list|
        error_report.each_line do |line|
          list << COLUMNS.zip(
            line.split('|').
              map(&:chomp),
          ).to_h
        end
      end
    end
  end
end
