###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Encapsulate the specifics of the menus on the site.
# site_menu method returns what should show up on the site-level menu
class Menu::Menu
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
      menu << warehouse_admin_menu
      menu << health_admin_menu
      menu << hmis_admin_menu
      menu << support_menu
      links_menu.each do |item|
        menu << item
      end
      menu << style_guide_menu unless Rails.env.production?
      menu << account_menu
      hmis_menu.each do |item|
        menu << item
      end
    end
  end

  def reports_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Reports'),
      id: 'reports',
      icon: 'icon-chart-bar',
      match_pattern: GrdaWarehouse::WarehouseReports::ReportDefinition.pluck(:url).map { |u| "^/#{u}.*" }.join('|'),
      match_pattern_terminator: '.*',
    )
    menu.add_child(hud_reports_menu)
    menu.add_child(warehouse_reports_menu)
    menu.add_child(op_analytics_menu)
    menu.add_child(favorites_menu)
    menu
  end

  def hud_reports_menu
    Menu::Item.new(
      user: user,
      path: hud_reports_path,
      visible: ->(user) { user.can_view_hud_reports? },
      title: Translation.translate('HUD Reports'),
      id: 'hud-reports',
    )
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

  def op_analytics_menu
    Menu::Item.new(
      user: user,
      visible: ->(user) { RailsDrivers.loaded.include?(:superset) && Superset.available? && GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(user).where(url: 'superset/warehouse_reports/reports').exists? },
      path: Superset.warehouse_login_url,
      title: Translation.translate('OP Analytics'),
      id: 'superset',
      target: :_blank,
      trailing_icon: 'icon-link-ext',
    )
  end

  def favorites_menu
    menu = Menu::Item.new(
      user: user,
      visible: ->(user) { user.can_view_any_reports? && user.favorite_reports.any? },
      path: warehouse_reports_path,
      title: Translation.translate('Favorite Reports'),
      id: 'warehouse-reports',
    )

    user.favorite_reports.each do |report|
      item = Menu::Item.new(
        user: user,
        visible: ->(user) { GrdaWarehouse::WarehouseReports::ReportDefinition.viewable_by(user).where(url: report.url).exists? },
        path: "/#{report.url}",
        title: report.name,
      )
      menu.add_child(item)
    end

    menu
  end

  def clients_menu
    menu = Menu::Item.new(
      user: user,
      # visible: ->(user) { user.can_manage_all_agencies? || user.can_manage_agency? || GrdaWarehouse::Config.client_search_available? && user.can_access_some_client_search? || user.can_access_some_cohorts? },
      title: Translation.translate('Clients'),
      icon: 'icon-users2',
      id: 'clients',
      match_pattern_terminator: '.*',
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
      always_open: true,
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { GrdaWarehouse::Config.get(:health_emergency_tracing).present? && user.can_edit_health_emergency_contact_tracing? },
        path: health_he_search_path,
        title: "#{GrdaWarehouse::Config.current_health_emergency_tracing_title} #{Translation.translate('Contact Tracing')}",
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

  def warehouse_admin_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Warehouse Admin'),
      icon: 'icon-cog',
      id: 'warehouse-administration',
      match_pattern_terminator: '.*',
    )

    menu.add_child(warehouse_access_menu)
    menu.add_child(legacy_access_menu) unless User.all_using_acls?
    menu.add_child(warehouse_configuration_menu)
    menu.add_child(warehouse_status_menu)
    menu
  end

  def warehouse_access_menu
    menu = Menu::Item.new(
      user: user,
      title: 'Access',
      id: 'user-access',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_roles? && User.anyone_using_acls? },
        path: admin_access_overviews_path,
        title: 'Getting Started',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_users? && User.anyone_using_acls? },
        path: admin_users_path,
        title: 'Users',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_roles? && User.anyone_using_acls? },
        path: admin_roles_path,
        title: 'Roles & Permissions',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_users? && User.anyone_using_acls? },
        path: admin_user_groups_path,
        title: 'User Groups',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_collections? && User.anyone_using_acls? },
        path: admin_collections_path,
        title: 'Collections',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_users? && User.anyone_using_acls? },
        path: admin_access_controls_path,
        title: 'Access Controls',
      ),
    )
    menu
  end

  def legacy_access_menu
    title = 'Access'
    title += ' (Legacy)' if User.anyone_using_acls?
    menu = Menu::Item.new(
      user: user,
      title: title,
      id: 'legacy-user-access',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_users? },
        path: admin_users_path,
        title: 'Users',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_roles? },
        path: admin_roles_path,
        title: 'Roles & Permissions',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_collections? },
        path: admin_groups_path,
        title: 'Groups',
      ),
    )
    menu
  end

  def warehouse_configuration_menu
    menu = Menu::Item.new(
      user: user,
      title: 'Configuration',
      id: 'warehouse-configuration',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_config? },
        path: admin_configs_path,
        title: 'Site Config',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_config? },
        path: admin_translation_keys_path,
        title: 'Translations',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_config? },
        path: admin_links_path,
        title: 'Links',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_theme? },
        path: edit_admin_theme_path,
        title: 'Theme',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_theme? },
        path: edit_admin_color_path,
        title: 'Colors',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_users? },
        path: admin_agencies_path,
        title: 'Agencies',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_auto_client_de_duplication? },
        path: admin_de_duplication_index_path,
        title: 'Client De-Duplication',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_auto_client_de_duplication? },
        path: admin_consent_limits_path,
        title: 'CoCs for Consent',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_add_administrative_event? },
        path: admin_administrative_events_path,
        title: 'Administrative Events',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_edit_warehouse_alerts? },
        path: admin_warehouse_alerts_path,
        title: 'Warehouse Alerts',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_assessments? && GrdaWarehouse::Config.get(:eto_api_available) },
        path: admin_eto_api_assessments_path,
        title: 'ETO TouchPoints',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_inbound_api_configurations? },
        path: admin_inbound_api_configurations_path,
        title: 'Inbound APIs',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_config? },
        path: oauth_applications_path,
        title: 'Oauth',
      ),
    )
    menu
  end

  def warehouse_status_menu
    menu = Menu::Item.new(
      user: user,
      title: 'Status',
      id: 'warehouse-status',
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_view_imports? },
        path: admin_dashboard_imports_path,
        title: 'Imports',
      ),
    )
    if RailsDrivers.loaded.include?(:ma_reports) && MaReports::CsgEngage::Credential.active.present?
      menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(user) { user.can_view_imports? },
          path: ma_reports_csg_engage_reports_path,
          title: 'CSG Engage',
        ),
      )
    end
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_add_administrative_event? },
        path: admin_delayed_jobs_path,
        title: 'Delayed Jobs',
      ),
    )
    menu.add_child(
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_manage_sessions? },
        path: admin_sessions_path,
        title: 'Sessions',
      ),
    )
    menu
  end

  def health_admin_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('Healthcare Admin'),
      icon: 'icon-cog',
      id: 'health-administration',
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
    menu
  end

  def hmis_admin_menu
    menu = Menu::Item.new(
      user: user,
      title: Translation.translate('HMIS Admin'),
      icon: 'icon-cog',
      match_pattern_terminator: '.*',
    )
    # If we don't have the ENV for HMIS, the path isn't available
    # Checking enforcement outside keeps it from throwing an error
    if HmisEnforcement.hmis_enabled?
      access_menu = Menu::Item.new(
        user: user,
        title: 'Access',
        id: 'hmis-access',
      )
      access_menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { context.hmis_admin_visible? },
          path: hmis_admin_access_overviews_path,
          title: Translation.translate('Getting Started'),
        ),
      )
      access_menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { context.hmis_admin_visible? },
          path: hmis_admin_users_path,
          title: Translation.translate('Users'),
        ),
      )
      access_menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { context.hmis_admin_visible? },
          path: hmis_admin_user_groups_path,
          title: Translation.translate('User Groups'),
        ),
      )
      access_menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { context.hmis_admin_visible? },
          path: hmis_admin_roles_path,
          title: Translation.translate('Roles & Permissions'),
        ),
      )
      access_menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { context.hmis_admin_visible? },
          path: hmis_admin_groups_path,
          title: Translation.translate('Collections'),
        ),
      )
      access_menu.add_child(
        Menu::Item.new(
          user: user,
          visible: ->(_user) { context.hmis_admin_visible? },
          path: hmis_admin_access_controls_path,
          title: Translation.translate('Access Controls'),
        ),
      )
      menu.add_child(access_menu)
    end

    menu
  end

  def hmis_menu
    hmis_data_sources = GrdaWarehouse::DataSource.hmis
    hmis_data_sources.map do |hmis_ds|
      title = hmis_data_sources.size == 1 ? Translation.translate('Open HMIS') : "Open #{hmis_ds.short_name}"
      Menu::Item.new(
        user: user,
        visible: ->(user) { user.can_access_hmis_data_source?(hmis_ds.id) },
        path: "//#{hmis_ds.hmis}",
        title: title,
        icon: 'icon-link-ext',
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
