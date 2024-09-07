###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2024::MissingDataConcern
  extend ActiveSupport::Concern

  def missing_data(user, filter: nil)
    @missing_data = {}
    @range = ::Filters::HudFilterBase.new(start: Date.current - 3.years, end: Date.current)
    project_ids = filter&.effective_project_ids || []
    @missing_data[:missing_housing_type] = missing_housing_types(user, project_ids: project_ids)
    @missing_data[:missing_geocode] = missing_geocodes(user, project_ids: project_ids)
    @missing_data[:missing_geography_type] = geography_types(user, project_ids: project_ids)
    @missing_data[:missing_zip] = missing_zips(user, project_ids: project_ids)
    @missing_data[:missing_operating_start_date] = operating_start_dates(user, project_ids: project_ids)
    @missing_data[:invalid_funders] = invalid_funders(user, project_ids: project_ids)
    @missing_data[:missing_coc_codes] = missing_coc_codes(user, project_ids: project_ids)
    @missing_data[:missing_inventory_coc_codes] = missing_inventory_coc_codes(user, project_ids: project_ids)
    @missing_data[:missing_inventory_household_types] = missing_inventory_household_types(user, project_ids: project_ids)
    @missing_data[:missing_inventory_start_dates] = missing_inventory_start_dates(user, project_ids: project_ids)
    @missing_data[:missing_hmis_participation_start_dates] = missing_hmis_participation_start_dates(user, project_ids: project_ids)
    @missing_data[:invalid_hmis_participation_types] = invalid_hmis_participation_types(user, project_ids: project_ids)

    @missing_data[:missing_projects] = @missing_data.values.flatten.uniq.sort_by(&:first)
    @missing_data[:show_missing_data] = @missing_data[:missing_projects].any?
    @missing_data
  end

  private def missing_data_columns
    {
      project_name: p_t[:ProjectName].to_sql,
      org_name: o_t[:OrganizationName].to_sql,
      project_type: p_t[:ProjectType].to_sql,
      funder: f_t[:Funder].to_sql,
      id: p_t[:id].to_sql,
      ds_id: p_t[:data_source_id].to_sql,
    }
  end

  private def missing_data_rows(scope)
    scope.pluck(*missing_data_columns.values).
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

  # this is imperfect, but only look at projects with enrollments open during the past three years
  private def enrollment_limit
    GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)
  end

  private def viewable_projects(user)
    GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded
  end

  private def missing_housing_types(user, project_ids: [])
    scope = viewable_projects(user).joins(:organization).
      left_outer_joins(:funders).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      where(HousingType: nil).
      housing_type_required.

      where(ProjectID: enrollment_limit)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    # There are a few required project descriptor fields.  Without these the report won't run cleanly
    missing_data_rows(scope)
  end

  private def missing_geocodes(user, project_ids: [])
    scope = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(Geocode: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def geography_types(user, project_ids: [])
    scope = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(GeographyType: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def missing_zips(user, project_ids: [])
    scope = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(Zip: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def operating_start_dates(user, project_ids: [])
    scope = GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.joins(:organization).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      left_outer_joins(:funders).
      where(OperatingStartDate: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def invalid_funders(user, project_ids: [])
    scope = viewable_projects(user).joins(:organization).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      joins(:funders).
      distinct.
      where(ProjectID: enrollment_limit).
      where(f_t[:StartDate].eq(nil))
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def missing_coc_codes(user, project_ids: [])
    scope = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(CoCCode: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def missing_inventory_coc_codes(user, project_ids: [])
    scope = GrdaWarehouse::Hud::Project.coc_funded.
      viewable_by(user, permission: :can_view_assigned_reports).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      joins(:project_cocs, :inventories, :organization).
      left_outer_joins(:funders).
      merge(GrdaWarehouse::Hud::ProjectCoc.where(pc_t[:CoCCode].not_eq(nil))).
      merge(GrdaWarehouse::Hud::Inventory.where(CoCCode: nil)).
      distinct
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def missing_inventory_household_types(user, project_ids: [])
    scope = GrdaWarehouse::Hud::Inventory.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(HouseholdType: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def missing_inventory_start_dates(user, project_ids: [])
    scope = GrdaWarehouse::Hud::Inventory.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(InventoryStartDate: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def missing_hmis_participation_start_dates(user, project_ids: [])
    scope = GrdaWarehouse::Hud::HmisParticipation.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(HMISParticipationStatusStartDate: nil)
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end

  private def invalid_hmis_participation_types(user, project_ids: [])
    scope = GrdaWarehouse::Hud::HmisParticipation.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(viewable_projects(user).hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: enrollment_limit).
      where(HMISParticipationType: [nil, 99])
    scope = scope.where(p_t[:id].in(project_ids)) if project_ids.any?
    missing_data_rows(scope)
  end
end
