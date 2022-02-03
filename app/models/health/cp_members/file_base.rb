###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented
module Health::CpMembers
  class FileBase < ::HealthBase
    acts_as_paranoid

    self.table_name = :cp_member_files

    phi_attr :file, Phi::FreeText, "Name of file"
    phi_attr :content, Phi::FreeText, "Content of file"

    belongs_to :user, optional: true

    mount_uploader :file, MemberRosterFileUploader

    def parse
      if check_header
        CSV.parse(content, headers: true) do |row|
          model_row = row.to_h
          model_row[:roster_file_id] = self.id

          model.create(model_row)
        end
        return true
      else
        return false
      end
    end

    def label
      type
    end

    def columns
      {}
    end

    def entries
      []
    end

    private def check_header
      incoming = CSV.parse(content.lines.first).flatten.map{|m| m&.strip}
      expected = parsed_expected_header.map{|m| m&.strip}
      # You can update the header string with File.read('path/to/file.csv').lines.first
      # Using CSV parse in case the quoting styles differ
      if incoming == expected
        return true
      else

        Rails.logger.error (incoming - expected).inspect
        Rails.logger.error (expected - incoming).inspect
      end
      return false
    end

    private def parsed_expected_header
      CSV.parse(expected_header).flatten
    end

    private def model
      raise NotImplementedError
    end

    private def expected_header
      raise NotImplementedError
    end
  end
end
