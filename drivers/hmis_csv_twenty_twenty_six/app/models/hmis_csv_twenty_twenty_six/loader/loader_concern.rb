###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :loader_log, optional: true, foreign_key: :loader_id, class_name: 'HmisCsvImporter::Loader::LoaderLog'

      def hmis_data
        @hmis_data ||= slice(*self.class.hmis_structure.keys)
      end

      def self.hud_csv_version
        '2026'
      end
    end
  end
end
