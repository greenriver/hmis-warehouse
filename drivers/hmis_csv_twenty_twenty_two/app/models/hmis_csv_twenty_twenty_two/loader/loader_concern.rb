###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentyTwo::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :loader_log, optional: true

      def hmis_data
        @hmis_data ||= slice(*self.class.hmis_structure(version: '2022').keys & attributes.keys)
      end
    end
  end
end
