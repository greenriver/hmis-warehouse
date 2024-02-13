###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Menu
  def menu
    menu = Menu::SiteMenu.new(user: current_user)

    hud_reports = MenuItem.new(
      user: current_user,
      visible: ->(user) { user.can_view_hud_reports? },
      path: public_send(Rails.application.config.hud_reports.values.min_by { |row| row[:title] }[:helper]),
      title: Translation.translate('HUD Reports'),
      id: 'hud-reports',
    )
    menu.add_item(hud_reports)
    menu
  end

  def page_menu
    menu.to_html
  end
end
