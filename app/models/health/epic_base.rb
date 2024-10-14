###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

    def self.epic_assoc(model:, primary_key:, foreign_key: nil)
      foreign_key ||= primary_key
      {
        primary_key: [
          :data_source_id,
          primary_key,
        ],
        foreign_key: [
          :data_source_id,
          foreign_key,
        ],
        class_name: "Health::#{model.to_s.camelize}",
        autosave: false,
      }
    end
  end
end
