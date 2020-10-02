###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Lsa::Fy2019
  class Base < Report
    include ArelHelper
    def self.report_name
      'LSA - FY 2019'
    end

    def report_group_name
      'Longitudinal System Analysis '
    end

    def file_name options
      "#{name}-#{options['coc_code']}"
    end

    def download_type
      :zip
    end

    def has_options?
      true
    end

    def has_custom_form?
      true
    end

    def title_for_options
      'Limits'
    end

    def self.available_projects(user:)
      # Project types are integral to LSA business logic; only ES, SH, TH, RRH, and PSH projects should be available to select as parameters.
      project_scope = GrdaWarehouse::Hud::Project.coc_funded.with_hud_project_type([1, 2, 3, 8, 13])
      GrdaWarehouse::Hud::Project.options_for_select(user: user, scope: project_scope)
    end

    def self.available_data_sources
      GrdaWarehouse::DataSource.importable
    end

    # def self.available_sub_populations
    #   [
    #     ['All Clients', :all_clients],
    #     ['Veteran', :veteran],
    #     ['Youth', :youth],
    #     ['Parenting Youth', :parenting_youth],
    #     ['Parenting Children', :parenting_children],
    #     ['Individual Adults', :individual_adults],
    #     ['Non Veteran', :non_veteran],
    #     ['Family', :family],
    #     ['Children', :children],
    #     ['Unaccompanied Minors', :unaccompanied_minors],
    #   ]
    # end

    def value_for_options options
      return '' unless options.present?

      display_string = "Report Start: #{options['report_start']}; Report End: #{options['report_end']}"
      display_string << "; CoC-Code: #{options['coc_code']}" if options['coc_code'].present?
      display_string << "; Data Source: #{GrdaWarehouse::DataSource.short_name(options['data_source_id'].to_i)}" if options['data_source_id'].present?
      display_string << project_id_string(options)
      display_string << project_group_string(options)
      display_string << sub_population_string(options)
      display_string
    end

    private def project_id_string options
      str = ''
      if options['project_id'].present?
        if options['project_id'].is_a?(Array)
          if options['project_id'].delete_if(&:blank?).any?
            str = "; Projects: #{options['project_id'].map do |m|
              GrdaWarehouse::Hud::Project.find_by_id(m.to_i)&.name || m if m.present? # rubocop:disable Metrics/BlockNesting
            end.compact.join(', ')}"
          end
        else
          str = "; Project: #{GrdaWarehouse::Hud::Project.find_by_id(options['project_id'].to_i)&.name || options['project_id']}"
        end
      end
      str
    end

    private def project_group_string options
      if (pg_ids = options['project_group_ids']&.compact) && pg_ids&.any?
        names = GrdaWarehouse::ProjectGroup.where(id: pg_ids).pluck(:name)
        return "; Project Groups: #{names.join(', ')}" if names.any?
      end
      ''
    end

    private def sub_population_string options
      if (sub_population = options['sub_population']) && sub_population.present?
        return "; Sub Population: #{sub_population.humanize.titleize}"
      end
      ''
    end

    def missing_data(user)
      @missing_data = {}
      @range = ::Filters::DateRange.new(start: Date.current - 3.years, end: Date.current)
      @missing_data[:missing_housing_type] = add_missing_housing_types(user)
      @missing_data[:missing_geocode] = add_missing_geocodes(user)
      @missing_data[:missing_geography_type] = add_geography_types(user)
      @missing_data[:missing_zip] = add_missing_zips(user)
      @missing_data[:missing_operating_start_date] = add_operating_start_dates(user)
      @missing_data[:invalid_funders] = add_invalid_funders(user)
      @missing_data[:missing_coc_codes] = add_missing_coc_codes(user)
      @missing_data[:missing_inventory_coc_codes] = add_missing_inventory_coc_codes(user)
      @missing_data[:missing_inventory_start_dates] = add_missing_inventory_start_dates(user)

      @missing_data[:missing_projects] = @missing_data.values.flatten.uniq.sort_by(&:first)
      @missing_data[:show_missing_data] = @missing_data[:missing_projects].any?
      @missing_data
    end

    private def missing_data_columns
      {
        project_name: p_t[:ProjectName].to_sql,
        org_name: o_t[:OrganizationName].to_sql,
        project_type: p_t[:computed_project_type].to_sql,
        funder: f_t[:Funder].to_sql,
        id: p_t[:id].to_sql,
        ds_id: p_t[:data_source_id].to_sql,
      }
    end

    private def add_missing_housing_types(user)
      # There are a few required project descriptor fields.  Without these the report won't run cleanly
      GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.joins(:organization).
        includes(:funders).
        where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
        where(HousingType: nil, housing_type_override: nil).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_missing_geocodes(user)
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
        includes(project: :funders).
        distinct.
        merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        where(Geocode: nil, geocode_override: nil).
        pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_geography_types(user)
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
        includes(project: :funders).
        distinct.
        merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        where(GeographyType: nil, geography_type_override: nil).
        pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_missing_zips(user)
      query = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
        includes(project: :funders).
        distinct.
        merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        where(Zip: nil, zip_override: nil)
      query.pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_operating_start_dates(user)
      GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.joins(:organization).
        includes(:funders).
        where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
        where(OperatingStartDate: nil, operating_start_date_override: nil).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_invalid_funders(user)
      GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.joins(:organization).
        includes(:funders).
        distinct.
        # merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)).
        where(f_t[:Funder].not_in(::HUD.funding_sources.keys)).
        pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_missing_coc_codes(user)
      query = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
        includes(project: :funders).
        distinct.
        merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        where(CoCCode: nil, hud_coc_code: nil)
      query.pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_missing_inventory_coc_codes(user)
      query = GrdaWarehouse::Hud::Project.coc_funded.
        where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
        joins(:project_cocs, :inventories, :organization).
        includes(:funders).
        merge(GrdaWarehouse::Hud::ProjectCoc.where(
          pc_t[:CoCCode].eq(nil).and(pc_t[:hud_coc_code].not_eq(nil)).
          or(pc_t[:CoCCode].not_eq(nil)),
        )).
        merge(GrdaWarehouse::Hud::Inventory.where(CoCCode: nil, coc_code_override: nil)).
        distinct
      query.pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end

    private def add_missing_inventory_start_dates(user)
      query = GrdaWarehouse::Hud::Inventory.joins(project: :organization).
        includes(project: :funders).
        distinct.
        merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
        where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
        where(InventoryStartDate: nil, inventory_start_date_override: nil)
      query.pluck(*missing_data_columns.values).
        map do |row|
          row = Hash[missing_data_columns.keys.zip(row)]
          {
            project: "#{row[:org_name]} - #{row[:project_name]}",
            project_type: row[:project_type],
            id: row[:id], data_source_id:
            row[:ds_id]
          }
        end
    end
  end
end
