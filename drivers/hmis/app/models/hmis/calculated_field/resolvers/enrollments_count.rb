# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::CalculatedField::Resolvers
  class EnrollmentsCount
    def call(client)
      client.enrollments.count
    end

    # def batch_call(client_ids)
    # preload clients with their enrollments and count enrollments by client id
    # ...
  end
end
