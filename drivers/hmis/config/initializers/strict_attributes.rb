###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Next tried this hook without eager loading. strict_attributes! is never called because table_exists? is not yet true
Rails.application.config.after_initialize do
  # forcing the whole application to eager load is probably not allowed though, is there any other way
  # Rails.application.eager_load! unless Rails.configuration.eager_load

  Hmis::Hud::Base.descendants.each do |model|
    model.strict_attributes! if model.table_exists?
  end
end
