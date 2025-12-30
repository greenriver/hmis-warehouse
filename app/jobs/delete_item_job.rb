###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DeleteItemJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  KNOWN_CLASSES = {
    'GrdaWarehouse::Hud::Project' => GrdaWarehouse::Hud::Project,
    'GrdaWarehouse::Hud::Organization' => GrdaWarehouse::Hud::Organization,
    'GrdaWarehouse::DataSource' => GrdaWarehouse::DataSource,
  }.freeze

  def perform(item_class:, item_id:)
    klass = known_class(item_class)
    raise "Unable to process background delete; Unknown class: #{item_class}" unless klass.present?

    item = klass.find(item_id)
    item.destroy_dependents! if item.respond_to?(:destroy_dependents!)
    item.destroy!
  end

  private def known_class(item_class)
    KNOWN_CLASSES[item_class]
  end

  def max_attempts
    1
  end
end
