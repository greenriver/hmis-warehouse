module Filters
  class HmisExport < ::ModelForm
    include ArelHelper
    attribute :start_date, Date, default: 1.years.ago.to_date
    attribute :end_date, Date, default: Date.today
    attribute :hash_status, Integer, default: 1
    attribute :period_type, Integer, default: 3
    attribute :directive, Integer, default: 2
    attribute :include_deleted,  Boolean, default: false
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    attribute :user_id, Integer, default: nil
    attribute :faked_pii, Boolean, default: false

    attribute :every_n_days, Integer, default: 0
    attribute :reporting_range, String, default: 'fixed'
    attribute :reporting_range_days, Integer, default: 0

    attribute :recurring_hmis_export_id, Integer, default: 0

    validates_presence_of :start_date, :end_date

    validate do
      if end_date.present? && start_date.present?
        if end_date < start_date
          errors.add :end_date, 'must follow start date'
        end
      end
    end

    def options_for_hmis_export export_version
      case export_version
      when :six_one_one
        options = {
          start_date: start_date,
          end_date: end_date,
          projects: effective_project_ids,
          period_type: period_type,
          directive: directive,
          hash_status: hash_status,
          include_deleted: include_deleted,
          faked_pii: faked_pii,
          user_id: user_id,

          recurring_hmis_export_id: recurring_hmis_export_id,
        }
      end
    end

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      if @effective_project_ids.empty?
        @effective_project_ids = all_project_ids
      end
      return @effective_project_ids.uniq
    end

    def effective_project_ids_from_projects
      project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      return [] unless user.can_edit_project_groups?
      GrdaWarehouse::ProjectGroup.joins(:projects).
        where(id: project_group_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_organizations
      GrdaWarehouse::Hud::Organization.joins(:projects).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user)).
        where(id: organization_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_data_sources
      GrdaWarehouse::DataSource.joins(:projects).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user)).
        where(id: data_source_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def adjust_reporting_period
      case reporting_range
        when 'fixed'
          return
        when 'n_days'
          @end_date = Date.today
          @start_date = end_date - reporting_range_days.days
        when 'month'
          last_month = Date.today.last_month
          @end_date = last_month.end_of_month
          @start_date = last_month.beginning_of_month
        when 'year'
          last_year = Date.today.last_year
          @end_date = last_year.end_of_year
          @start_date = last_year.beginning_of_year
      end
    end

    def all_project_ids
      GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id)
    end

    def user
      User.find(user_id)
    end
  end
end