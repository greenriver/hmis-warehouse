###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO:
# 1. set collapsed state based on path
# 2. Hover state
module Menu
  def site_menu
    ::Menu::Menu.new(user: current_user, context: self).site_menu
  end
end
