###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::ClientDependent
  extend ActiveSupport::Concern

  included do
    def client_id=(item)
      self.personal_id = item.personal_id
      self.data_source_id = item.data_source_id
      self # rubocop:disable Lint/Void
    end
  end
end
