###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# trying commenting this whole thing out to see if tests succeed
# # if changing this code and then testing it using rspec, need to DISABLE_SPRING=1
# Rails.application.config.to_prepare do
#   # without eager_load, Hmis::Hud::Base.descendants == [].
#   # Rails.application.eager_load!
#
#   Hmis::Hud::Base.descendants.each do |model|
#     if model.table_exists?
#       model.columns.each do |column|
#         case column.type
#         when :integer
#           model.class_eval do
#             attribute column.name, Hmis::StrictInteger.new
#           end
#         when :decimal
#           model.class_eval do
#             attribute column.name, Hmis::StrictDecimal.new
#           end
#         end
#       end
#     else
#       # everybody is loaded at this point, the breakpoint never hits.
#       # binding.pry
#     end
#   end
# end
