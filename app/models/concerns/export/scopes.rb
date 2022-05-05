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
        c_scope.joins(:warehouse_client_source).
          where(enrollment_exists_for_client).
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
        when 3
          # FIXME: open_during_range may need to include logic to include deleted Exits
          e_scope = e_scope.open_during_range(@range)
        when 1
          # no-op
        end
        e_scope.preload(:project, :client)
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
