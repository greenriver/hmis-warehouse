###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Export::Scopes
  extend ActiveSupport::Concern

  included do
    def client_scope
      # include any client with an open enrollment
      # during the report period in one of the involved projects
      @client_scope ||= begin
        if @export&.include_deleted
          c_scope = client_source.with_deleted
        else
          c_scope = client_source
        end
        c_scope.destination.where(id: c_scope.joins(:warehouse_client_source).
          where(enrollment_exists_for_client).select(wc_t[:destination_id])).
          preload(:source_clients)
      end
    end

    def enrollment_scope
      @enrollment_scope ||= begin
        # Choose all enrollments open during the range at one of the associated projects.
        if @export&.include_deleted
          e_scope = enrollment_source.with_deleted
        else
          e_scope = enrollment_source.joins(:client)
        end
        e_scope = e_scope.where(project_exists_for_enrollment)
        case @export&.period_type
        when 3 # Reporting period
          # FIXME: open_during_range may need to include logic to include deleted Exits
          e_scope = e_scope.open_during_range(@range)
        when 2 # Effective (not implemented or exposed)
          raise NotImplementedError
        when 1 # Updated (handled within the individual models)
          # no-op
        else # rubocop:disable Style/EmptyElse
          # Used for tests to count things
        end

        # limit enrollment coc to the cocs chosen, and any random thing that's not a valid coc
        # Only include enrollments where:
        # 1. HouseholdID is null → check enrollment's own CoC
        # 2. HouseholdID exists and HoH exists with valid CoC → include
        # 3. HouseholdID exists but no HoH exists → check enrollment's own CoC (fallback)
        e_scope = e_scope.where(hoh_exists_with_valid_coc_clause) if @coc_codes.present?
        # puts "e_scope: #{e_scope.to_sql}"
        e_scope.distinct.preload(:project, :client)
      end
    end

    def project_scope
      @project_scope ||= begin
        p_scope = project_source.where(id: @projects)
        # Limit projects if CoC codes are chosen to only those that operate in the
        # chosen CoC.
        # This is necessary because a project that only operates in a single non-selected CoC will
        # trigger the enrollment cleanup and place those enrollments into the other CoC
        if @coc_codes.present?
          p_scope = p_scope.where(
            id: GrdaWarehouse::Hud::Project.joins(:project_cocs).
              merge(GrdaWarehouse::Hud::ProjectCoc.where(CoCCode: @coc_codes)),
          )
        end
        p_scope = p_scope.with_deleted if @export&.include_deleted
        p_scope.preload(:organization)
      end
    end

    def enrollment_exists_for_client
      if @export&.include_deleted
        e_scope = enrollment_source.with_deleted
      else
        e_scope = enrollment_source
      end
      case @export&.period_type
      when 3
        e_scope = e_scope.open_during_range(@range)
      when 1
        # no-op
      end
      # limit enrollment coc to the cocs chosen, and any random thing that's not a valid coc
      # Only include enrollments where:
      # 1. HouseholdID is null → check enrollment's own CoC
      # 2. HouseholdID exists and HoH exists with valid CoC → include
      # 3. HouseholdID exists but no HoH exists → check enrollment's own CoC (fallback)
      e_scope = e_scope.where(hoh_exists_with_valid_coc_clause) if @coc_codes.present?
      e_scope = e_scope.where(
        e_t[:PersonalID].eq(c_t[:PersonalID]).
          and(e_t[:data_source_id].eq(c_t[:data_source_id])),
      ).where(
        project_exists_for_enrollment,
      ).arel.exists
      e_scope
    end

    def project_exists_for_enrollment
      project_scope.where(
        p_t[:ProjectID].eq(e_t[:ProjectID]).
          and(p_t[:data_source_id].eq(e_t[:data_source_id])),
      ).arel.exists
    end

    # Only include enrollments where:
    # 1. HouseholdID is null → check enrollment's own CoC
    # 2. HouseholdID exists and HoH exists with valid CoC → include
    # 3. HouseholdID exists but no HoH exists → check enrollment's own CoC (fallback)
    def hoh_exists_with_valid_coc_clause
      e_t[:HouseholdID].eq(nil).and(enrollment_coc_query(e_t)).
        or(
          Arel::Nodes::Grouping.new(
            e_t[:HouseholdID].not_eq(nil).and(
              hoh_exists_with_valid_coc.or(
                Arel::Nodes::Not.new(hoh_exists_at_all).and(enrollment_coc_query(e_t)),
              ),
            ),
          ),
        )
    end

    # Used for limiting enrollments that are missing HouseholdID to those where the Enrollment CoC is matching, invalid, or missing
    def enrollment_coc_query(table)
      table[:EnrollmentCoC].in(@coc_codes).
        or(table[:EnrollmentCoC].eq(nil)).
        or(table[:EnrollmentCoC].not_in(HudHelper.util.cocs.keys))
    end

    # For enrollments with a HouseholdID, check if a HoH exists with matching CoC
    def hoh_exists_with_valid_coc
      hoh_t = GrdaWarehouse::Hud::Enrollment.arel_table.alias('hoh_t')
      GrdaWarehouse::Hud::Enrollment.from(hoh_t).where(
        hoh_t[:HouseholdID].eq(e_t[:HouseholdID]).
          and(hoh_t[:data_source_id].eq(e_t[:data_source_id])).
          and(hoh_t[:ProjectID].eq(e_t[:ProjectID])).
          and(hoh_t[:RelationshipToHoH].eq(1)).
          and(enrollment_coc_query(hoh_t)),
      ).arel.exists
    end

    # Check if ANY HoH exists for this household (regardless of CoC)
    def hoh_exists_at_all
      hoh_t = GrdaWarehouse::Hud::Enrollment.arel_table.alias('hoh_exists_t')
      GrdaWarehouse::Hud::Enrollment.from(hoh_t).where(
        hoh_t[:HouseholdID].eq(e_t[:HouseholdID]).
          and(hoh_t[:data_source_id].eq(e_t[:data_source_id])).
          and(hoh_t[:ProjectID].eq(e_t[:ProjectID])).
          and(hoh_t[:RelationshipToHoH].eq(1)),
      ).arel.exists
    end
  end
end
