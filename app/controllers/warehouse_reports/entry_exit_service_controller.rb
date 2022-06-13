###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class EntryExitServiceController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_limited, only: [:index]
    def index
      # Clients who received services for one-day enrollments in housing related projects.
      # this is a translation of an original raw SQL query into Arel
      @enrollments = GrdaWarehouse::Hud::Client.joins(
        :warehouse_client_source,
        enrollments: [:project, :exit, :services, :organization],
      ).
        where(
          p_t[project_source.project_type_column].in(
            project_source::RESIDENTIAL_PROJECT_TYPE_IDS,
          ),
        ).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        where(ex_t[:ExitDate].eq s_t[:DateProvided]).
        where(e_t[:EntryDate].eq s_t[:DateProvided]).
        distinct

      respond_to do |format|
        format.html do
          @pagy, @enrollments = pagy(@enrollments, items: 50)
          @data = @enrollments.pluck(*columns.values).map { |r| row_to_hash(r) }
        end
        format.xlsx do
          @data = @enrollments.pluck(*columns.values).map { |r| row_to_hash(r) }
        end
      end
    end

    private def row_to_hash(row)
      row_hash = Hash[columns.keys.zip(row)]
      safe_project_name = GrdaWarehouse::Hud::Project.confidentialize_name(current_user, row_hash[:project_name], row_hash[:project_confidential] || row_hash[:organization_confidential])
      row_hash[:project_name] = safe_project_name
      row_hash
    end

    def columns
      {
        EnrollmentID: s_t[:EnrollmentID],
        EntryDate: e_t[:EntryDate],
        DateProvided: s_t[:DateProvided],
        ExitDate: ex_t[:ExitDate],
        PersonalID: ex_t[:PersonalID],
        data_source_id: ex_t[:data_source_id],
        FirstName: c_t[:FirstName],
        LastName: c_t[:LastName],
        destination_id: wc_t[:destination_id],
        project_id: p_t[:id],
        project_name: p_t[:ProjectName],
        project_type: p_t[project_source.project_type_column].as('project_type'),
        RecordType: s_t[:RecordType],
        project_confidential: p_t[:confidential],
        organization_confidential: o_t[:confidential],
      }
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end
  end
end
