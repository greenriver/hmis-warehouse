###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::DataSource < Types::BaseObject
    # object is GrdaWarehouse::DataSource

    field :id, ID, null: false
    field :name, String, null: false
    field :is_current_data_source, Boolean, null: false

    def is_current_data_source # rubocop:disable Naming/PredicateName
      current_user.hmis_data_source_id == object.id
    end
  end
end
