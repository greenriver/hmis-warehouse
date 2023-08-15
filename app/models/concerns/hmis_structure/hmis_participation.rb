###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::HmisParticipation
  extend ActiveSupport::Concern
  include ::HmisStructure::Base

  included do
    self.hud_key = :HMISParticipationID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(_version: nil)
      {}
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateUpdated] => nil,
        [:ProjectID] => nil,
        [:ProjectType] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
