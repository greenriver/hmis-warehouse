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

    # To be implemented in subclasses:

    # Generate and deliver the scheduled document
    def deliver(_user)
      raise 'Not implemented'
    end

    # Should the scheduled document be delivered at the current time?
    # The processor will periodically poll the defined scheduled documents, and invoke 'deliver' on
    # the ones that return true to this query.
    def should_be_delivered?
      false
    end

    # The names of the parameters that should be added to the permitted parameters list for a scheduled document
    # class
    def params
      []
    end
  end
end
