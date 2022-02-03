###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::ImportLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
  serialize :files
  serialize :import_errors
  serialize :summary
  belongs_to :data_source
  belongs_to :upload, optional: true

  scope :viewable_by, ->(user) do
    where(data_source_id: GrdaWarehouse::DataSource.directly_viewable_by(user).select(:id))
  end

  scope :diet, -> do
    select(attribute_names - ['summary', 'import_errors', 'zip'])
  end

  def import_time(details: false)
    return unless persisted?

    if completed_at.present?
      seconds = ((completed_at - created_at) / 1.minute).round * 60
      distance_of_time_in_words(seconds)
    elsif upload.present?
      upload.import_time(details: details)
    else
      return 'failed' if updated_at < 2.days.ago

      'processing...'
    end
  end
  # Overrides some methods, so must be included at the end
  include RailsDrivers::Extensions
end
