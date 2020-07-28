###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PII
  class RekeyJob < BaseJob
    queue_as :pii

    def perform
      Rake::Task['secrets:rotate'].execute
    end
  end
end
