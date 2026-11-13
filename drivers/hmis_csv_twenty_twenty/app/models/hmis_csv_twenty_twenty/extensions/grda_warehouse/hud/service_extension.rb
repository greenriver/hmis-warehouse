###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module ServiceExtension
    extend ActiveSupport::Concern

    included do
      has_many :imported_items_2020, class_name: 'HmisCsvTwentyTwenty::Importer::Service', primary_key: [:ServicesID, :data_source_id], foreign_key: [:ServicesID, :data_source_id]
      has_many :loaded_items_2020, class_name: 'HmisCsvTwentyTwenty::Loader::Service', primary_key: [:ServicesID, :data_source_id], foreign_key: [:ServicesID, :data_source_id]
    end
  end
end
