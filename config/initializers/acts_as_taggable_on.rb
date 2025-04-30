# frozen_string_literal: true

ActsAsTaggableOn.setup do |config|
  # Store the tags in the warehouse
  config.base_class = 'GrdaWarehouseBase'
end
