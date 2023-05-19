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
      :medicaid_id, # ID_MEDICAID
      :homeless_flag, # RDC_HOMELESS_FLAG
      :field, # FIELD
      :error_code, # CDE_ERROR
      :description, # MSG
    ].freeze
    def process_response
      problems.each do |error|
        # If the medicaid ID was flagged by MH, mark it as invalid
        next unless error[:error_code] == '3' && error[:field] == 'Field 1'

        external_id = ExternalId.find_by(identifier: error[:medicaid_id])
        if external_id.present?
          external_id.update(invalidated_at: DateTime.current)
          external_ids << external_id
        end
      end
      save!
    end

    def problems
      @problems ||= [].tap do |list|
        error_report.each_line.with_index do |line, i|
          next if i.zero?

          list << COLUMNS.zip(line.split('|').map { |m| m.chomp.gsub('"', '') }).to_h
        end
      end
    end
  end
end
