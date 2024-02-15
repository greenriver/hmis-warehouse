###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Encapsulate the specifics of the menus on the site.
# site_menu method returns what should show up on the site-level menu
class Menu::Menu < OpenStruct
  include Rails.application.routes.url_helpers
  attr_accessor :user, :context
  def initialize(user:, context:)
    @user = user
    @context = context
  end

  def site_menu
    [].tap do |menu|
      menu << reports_menu
      menu << clients_menu
      menu << health_menu
      menu << data_menu
      menu << administration_menu
      hmis_menu.each do |item|
        menu << item
      end
      menu << support_menu
      links_menu.each do |item|
        menu << item
      end
      menu << style_guide_menu
      menu << account_menu
    end
  end

  def reports_menu
    Menu::Item.new(
      user: user,
      title: Translation.translate('Reports'),
      id: 'reports',
      icon: 'icon-chart-bar',
      children: [hud_reports_menu, warehouse_reports_menu],
    )
  end

  def hud_reports_menu
    reports = Rails.application.config.hud_reports.values.map { |report| [report[:title], context.public_send(report[:helper])] }.uniq
    menu = Menu::Item.new(
      user: user,
      path: reports.first.last,
      title: Translation.translate('HUD Reports'),
      id: 'hud-reports',
    )
    reports.each do |report_name, path|
      item = Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_view_hud_reports? },
        path: path,
        title: Translation.translate(report_name),
        id: "hud-reports-#{report_name.downcase.gsub(' ', '-')}",
      )
      menu.add_child(item)
    end

    menu
  end

  def warehouse_reports_menu
    Menu::Item.new(
      user: user,
      visible: ->(user) { user.can_view_any_reports? },
      path: warehouse_reports_path,
      title: Translation.translate('Warehouse Reports'),
      id: 'warehouse-reports',
    )
  end

  # TODO: perhaps the visibility should boil up from the children?
  def clients_menu
    menu = Menu::Item.new(
      user: user,
      # visible: ->(user) { user.can_manage_all_agencies? || user.can_manage_agency? || GrdaWarehouse::Config.client_search_available? && user.can_access_some_client_search? || user.can_access_some_cohorts? },
      title: Translation.translate('Clients'),
      icon: 'icon-users2',
      id: 'clients',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_all_agencies? },
        path: assigned_all_agencies_path,
        title: Translation.translate('All Assigned Clients'),
      ),
    )
    title = if user.can_view_aggregate_health? || user.can_view_patients_for_own_agency?
      Translation.translate('My Agency\'s HMIS Clients')
    else
      Translation.translate('My Agency\'s Clients')
    end
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_agency? },
        path: assigned_agencies_path,
        title: title,
      ),
    )
    title = if user.can_view_aggregate_health? || user.can_view_patients_for_own_agency?
      Translation.translate('My HMIS Clients')
    else
      Translation.translate('My Clients')
    end
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.user_clients.exists? },
        path: assigned_clients_path,
        title: title,
      ),
    )

    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { GrdaWarehouse::Config.client_search_available? && user.can_access_some_client_search? },
        path: clients_path,
        title: Translation.translate('Client Search'),
      ),
    )

    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_access_some_cohorts? },
        path: cohorts_path,
        title: Translation.translate('Cohorts'),
      ),
    )

    menu
  end

  def health_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Care Hub'),
      icon: 'icon-heart-empty',
      id: 'care-hub',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { GrdaWarehouse::Config.get(:health_emergency_tracing).present? && user.can_edit_health_emergency_contact_tracing? },
        path: health_he_search_path,
        title: "#{GrdaWarehouse::Config.currrent_health_emergency_tracing_title} #{Translation.translate('Contact Tracing')}",
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_view_patients_for_own_agency? && user.health_agencies.any? },
        path: health_patients_path,
        title: Translation.translate('My Agency\'s Patients'),
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_administer_health? || user.team_mates.exists? },
        path: health_team_patients_path,
        title: Translation.translate('My Team\'s Patients'),
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_view_patients_for_own_agency? && user.health_agencies.any? },
        path: health_my_patients_path,
        title: Translation.translate('My Patients'),
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { !(user.can_view_patients_for_own_agency? && user.health_agencies.any?) && user.can_view_some_vprs? },
        path: health_flexible_service_my_vprs_path,
        title: Translation.translate('My Patients'),
      ),
    )

    menu
  end

  def data_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Data'),
      icon: 'icon-spin1',
      id: 'data',
    )
    path = ad_hoc_data_sources_path
    path = data_sources_path if (user.can_view_imports_projects_or_organizations? || user.can_upload_hud_zips? || user.can_manage_some_ad_hoc_ds?) && (user.can_view_projects? || user.can_view_organizations? || user.can_upload_hud_zips?)
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_view_imports_projects_or_organizations? || user.can_upload_hud_zips? || user.can_manage_some_ad_hoc_ds? },
        path: path,
        title: Translation.translate('Data Sources'),
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_see_raw_hmis_data? },
        path: source_data_path,
        title: Translation.translate('HMIS Source Data'),
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_some_project_groups? },
        path: project_groups_path,
        title: Translation.translate('Project Groups'),
      ),
    )

    menu
  end

  def administration_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Administration'),
      icon: 'icon-cog',
      id: 'administration',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_users? || user.can_edit_translations? || user.can_view_imports? },
        path: user.admin_dashboard_landing_path,
        title: Translation.translate('Warehouse Admin'),
      ),
    )
    path = if user.can_approve_patient_assignments?
      review_admin_health_patient_referrals_path
    elsif (user.can_manage_health_agency? || user.can_manage_patients_for_own_agency?) && user.health_agencies.any?
      review_admin_health_agency_patient_referrals_path
    else
      admin_health_admin_index_path
    end
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { GrdaWarehouse::Config.get(:healthcare_available) && (user.can_administer_health? || user.can_manage_health_agency? || user.has_patient_referral_review_access?) },
        path: path,
        title: Translation.translate('Healthcare Admin'),
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(_user) { context.hmis_admin_visible? },
        path: hmis_admin_users_path,
        title: Translation.translate('HMIS Admin'),
      ),
    )

    menu
  end

  def hmis_menu
    # NOTE: eventually we should use the data source name here, maybe concatenated with HMIS, but currently that would be HMIS HMIS
    GrdaWarehouse::DataSource.hmis.distinct.map do |hmis_ds|
      Menu::Item.new(
        user: user,
        visible: ->(_user) { HmisEnforcement.hmis_enabled? },
        path: "//#{hmis_ds.hmis}",
        title: Translation.translate('HMIS'),
        icon: 'icon-house',
        target: :_blank,
      )
    end
  end

  private def help_for_path
    context.help_for_path
  end

  def support_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Support'),
      icon: 'icon-question',
      id: 'support',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_help? },
        path: help_index_path,
        title: Translation.translate('Help Documents'),
      ),
    )
    if help_for_path
      menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(user) { user.can_edit_help? && help_for_path },
          path: edit_help_path(help_for_path),
          title: Translation.translate('Edit Help'),
          data: { loads_in_pjax_modal: true },
        ),
      )
    else
      menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(user) { user.can_edit_help? && !help_for_path },
          path: new_help_path(controller_path: context.controller_path, action_name: context.action_name),
          title: Translation.translate('Add Help Here'),
          data: { loads_in_pjax_modal: true },
        ),
      )
    end
    if help_for_path
      path = nil
      target = nil
      data = {}
      if help_for_path.external?
        path = help_for_path.external_url
        target = :_blank
      else
        path = help_path(help_for_path)
        data = { loads_in_pjax_modal: true }
      end
      menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { help_for_path },
          path: path,
          title: Translation.translate('Help'),
          data: data,
          target: target,
        ),
      )
    end

    menu
  end

  def links_menu
    Link.for(:menu).map do |link|
      options = {
        user: user,
        visible: ->(_user) { true },
        path: link.url,
        title: link.label,
      }
      options[:subject] = link.subject if link.subject.present?
      Menu::Item.new(**options)
    end
  end

  def style_guide_menu
    Menu::Item.new(
      user: user,
      visible: ->(_user) { ! Rails.env.production? },
      path: style_guide_path,
      title: 'Style Guide',
      icon: 'icon-equalizer',
    )
  end

  def account_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Account'),
      icon: 'icon-user',
      id: 'account',
    )
    sub_menu = Menu::Item.new(
      user: user,
      path: edit_account_path,
      title: user.name,
      id: 'account-name',
    )
    sub_menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(_user) { true },
        path: edit_account_path,
        title: Translation.translate('Edit Account'),
      ),
    )
    sub_menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_view_some_secure_files? },
        path: secure_files_path,
        title: Translation.translate('Secure Files'),
      ),
    )
    sub_menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(_user) { true },
        path: destroy_user_session_path,
        title: Translation.translate('Sign Out'),
        icon: 'icon-exit',
        data: { method: :delete },
      ),
    )
    menu.add_child(sub_menu)
    menu
  end
end
