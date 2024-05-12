###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::EnrollmentDependent
  extend ActiveSupport::Concern

  included do
    def enrollment=(item)
      self.enrollment_id = item.enrollment_id
      self.personal_id = item.personal_id
      self.project_id = item.project_id if self.class.column_names.include?('ProjectID')
      self.data_source_id = item.data_source_id
      self # rubocop:disable Lint/Void
    end
  end
end
