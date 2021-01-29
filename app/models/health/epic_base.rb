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

    def self.source_key= key
      @source_key = key
    end

    def self.source_key
      @source_key
    end

    # override as necessary
    # don't forget to call super
    def self.clean_value key, value
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

    def self.use_tsql_import?
      true
    end
  end
end
