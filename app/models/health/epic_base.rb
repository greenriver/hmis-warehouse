###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class EpicBase < Base
    self.abstract_class = true

    attr_accessor :source_key

    # override as necessary
    # don't forget to call super
    def self.clean_value(_key, value)
      if value.is_a? FalseClass
        value
      else
        value.presence
      end
    end

    # override as necessary
    def clean_row(row:, data_source_id:) # rubocop:disable Lint/UnusedMethodArgument
      row
    end

    def self.process_new_data(values)
      return unless values.present?

      where(data_source_id: values.first[:data_source_id]).delete_all # Rather than merge, discard old data
      import(values)
    end
  end
end
