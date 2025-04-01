###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Concerns::WithStrictAttributes
  extend ActiveSupport::Concern

  included do
    if table_exists?
      columns.each do |column|
        case column.type
        when :integer
          attribute column.name, Hmis::StrictInteger.new
        when :decimal
          attribute column.name, Hmis::StrictDecimal.new
        end
      end
    else # rubocop:disable Style/EmptyElse
      # Again, not all models have the table loaded yet. But I'm baffled that it's not the same subset that you see
      # when calling self.inherited in Hmis::Hud::Base. If you set a breakpoint here, the following models hit:
      # Hmis::Hud::Project
      # Hmis::Hud::User
      # Hmis::Hud::Enrollment
      # Hmis::Hud::EmploymentEducation
      # binding.pry
    end
  end
end
