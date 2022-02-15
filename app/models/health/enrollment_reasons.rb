###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Describes patient enrollments and contains PHI
# Control: PHI attributes documented

require 'roo'
module Health
  class EnrollmentReasons < HealthBase

    phi_attr :content, Phi::Bulk, "Enrollment reasons" # contains EDI serialized PHI

    mount_uploader :file, EnrollmentReasonsFileUploader

    def reasons
      return {} unless content.present?

      @reasons ||= begin
        csv = if content_type.in?(['text/plain', 'text/csv'])
          sheet = ::Roo::CSV.new(StringIO.new(content))
          sheet.parse(headers: true).drop(1)
        else
          sheet = ::Roo::Excelx.new(StringIO.new(content).binmode)
          return {} if sheet&.first_row.blank?
          sheet.parse(headers: true).drop(1)
        end
        csv.map!{ |row| row.transform_keys { |key| key.gsub(/\W/, '').downcase } }
        csv.map{ |row| [row["medicaid_id"], row["start_reason_desc"]] }.to_h
      end
    end
  end
end
