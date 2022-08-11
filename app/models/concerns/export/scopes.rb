###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
        e_scope = e_scope.
          joins(e_t.join(p_t).on(
            e_t[:ProjectID].eq(p_t[:ProjectID]).
              and(e_t[:data_source_id].eq(p_t[:data_source_id])),
          ).join_sources).
          # Plucking project ids should never be > ~10k, and is usually _way_ faster than merging the scope
          where(p_t[:id].in(project_scope.pluck(:id)))
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
        e_scope = e_scope.joins(:enrollment_cocs).where(ec_t[:CoCCode].in(Array(@coc_codes))) if @coc_codes.present?
        e_scope.distinct.preload(:project, :client)
      end
    end

    def project_scope
      @project_scope ||= begin
        p_scope = project_source.where(id: @projects)
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
      e_scope.where(
        e_t[:PersonalID].eq(c_t[:PersonalID]).
          and(e_t[:data_source_id].eq(c_t[:data_source_id])),
      ).where(
        project_exists_for_enrollment,
      ).arel.exists
    end

    def project_exists_for_enrollment
      project_scope.where(
        p_t[:ProjectID].eq(e_t[:ProjectID]).
          and(p_t[:data_source_id].eq(e_t[:data_source_id])),
      ).arel.exists
    end
  end
end
