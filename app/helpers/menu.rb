###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Menu
  # FIXME: rewrite this as a recursive function so we can have as deeply nested menu as we want
  def page_menu
    tag.ol(class: 'site-menu o-menu__group list-unstyled') do
      menu.children.each do |_path, item|
        # if item.visible.call(current_user)
        concat(render_menu_item(item))
      end
    end
  end

  def render_menu_item(item)
    if item.children?
      tag.li(class: 'menu-item menu-item-with-children o-menu__item') do
        concat(tag.a(item.title, class: 'o-menu__link', href: item.path))
        item.children.each do |_path, child|
          concat(render_menu_item(child))
        end
      end
    else
      tag.li(class: 'menu-item o-menu__item') do
        concat(tag.a(item.title, class: 'o-menu__link', href: item.path))
      end
    end
  end

  def menu
    menu = Menu::SiteMenu.new(user: current_user)

    menu.add_child(hud_reports_menu)
    menu
  end

  def hud_reports_menu
    reports = Rails.application.config.hud_reports.values.map { |report| [report[:title], public_send(report[:helper])] }.uniq
    hud_reports = Menu::Item.new(
      user: current_user,
      visible: ->(user) { user.can_view_hud_reports? },
      path: reports.first.last,
      title: Translation.translate('HUD Reports'),
      id: 'hud-reports',
    )
    reports.each do |report_name, path|
      item = Menu::Item.new(
        user: current_user,
        visible: ->(user) { user.can_view_hud_reports? },
        path: path,
        title: Translation.translate(report_name),
        id: "hud-reports-#{report_name.downcase.gsub(' ', '-')}",
      )
      hud_reports.add_child(item)
    end

    hud_reports
  end
end
