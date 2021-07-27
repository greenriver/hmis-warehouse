###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Synthetic
  def self.available_event_types
    Rails.application.config.synthetic_event_types || []
  end

  def self.add_event_type(event_type)
    event_types = available_event_types
    event_types << event_type
    Rails.application.config.synthetic_event_types = event_types
  end
end
