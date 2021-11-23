###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ScheduledDocuments::Base < HealthBase
    self.table_name = :scheduled_documents

    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    validates :name, presence: true

    def params
      []
    end
  end
end
