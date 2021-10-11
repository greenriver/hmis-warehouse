###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class EtoApiConfig < GrdaWarehouseBase
    has_paper_trail
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    belongs_to :data_source, optional: true

    scope :active, -> do
      where(active: true)
    end

    def touchpoint_fields_for_input
      touchpoint_fields.to_json if touchpoint_fields
    end

    def demographic_fields_for_input
      demographic_fields.to_json if demographic_fields
    end

    def demographic_fields_with_attributes_for_input
      demographic_fields_with_attributes.to_json if demographic_fields_with_attributes
    end

    def additional_fields_for_input
      additional_fields.to_json if additional_fields
    end
  end
end
