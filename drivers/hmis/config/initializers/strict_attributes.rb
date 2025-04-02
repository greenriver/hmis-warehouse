###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# discussed with Gig and agreed that it would be more clear to put this in the models themselves (aka in a concern)
# rather than here in a hook. However, I'm leaving this in the PR for discussion since I need to better understand rails model loading.
# In this strategy, as long as we call Rails.application.eager_load!, all the models' tables are loaded.

# # if changing this code and then testing it using rspec, need to DISABLE_SPRING=1
# Rails.application.config.after_initialize do
#   # without eager_load, Hmis::Hud::Base.descendants == [].
#   Rails.application.eager_load!
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
