module Reporting::MonthlyReports::MonthlyReportCharts
  extend ActiveSupport::Concern
  included do

    attr_accessor :organization_ids
    attr_accessor :project_ids
    attr_accessor :months

    # accepts an array of months in the format:
    # [[year, month], [year, month]]
    scope :in_months, -> (months) do
      return none unless months.present?
      ors = months.map do |year, month|
        arel_table[:year].eq(year).and(arel_table[:month].eq(month)).to_sql
      end
      where(ors.join(' OR '))
    end

    scope :enrolled, -> do
      where(enrolled: true)
    end

    scope :active, -> do
      where(active: true)
    end

    scope :entered, -> do
      where(entered: true)
    end

    scope :exited, -> do
      where(exited: true)
    end

    scope :first_enrollment, -> do
      where(first_enrollment: true)
    end

    scope :re_entry, -> do
      where(arel_table[:days_since_last_exit].gt(60))
    end

    scope :housed, -> do
      where(destination_id: HUD.permanent_destinations)
    end

    scope :for_organizations, -> (organization_ids) do
      return all unless organization_ids.present?
      where(organization_id: organization_ids)
    end

    scope :for_projects, -> (project_ids) do
      return all unless project_ids.present?
      where(project_id: project_ids)
    end

    def months_in_dates
      @months_in_dates ||= months.map{|year, month| Date.new(year, month, 1) }
    end

    def enrolled_clients
      self.class.enrolled.in_months(months).
        for_organizations(organization_ids).
        for_projects(project_ids)
    end

    def enrolled_client_count
      enrolled_clients.select(:client_id).distinct.count
    end

    def enrolled_household_count
      enrolled_clients.select(:household_id).distinct.count
    end

    def active_clients
      self.class.active.in_months(months).
        for_organizations(organization_ids).
        for_projects(project_ids)
    end

    def active_client_count
      active_clients.select(:client_id).distinct.count
    end

    def active_household_count
      active_clients.select(:household_id).distinct.count
    end

    def entered_clients
      self.class.entered.in_months(months).
        for_organizations(organization_ids).
        for_projects(project_ids)
    end

    def entered_client_count
      entered_clients.select(:client_id).distinct.count
    end

    def entered_household_count
      entered_clients.select(:household_id).distinct.count
    end

    def exited_clients
      self.class.exited.in_months(months).
        for_organizations(organization_ids).
        for_projects(project_ids)
    end

    def exited_client_count
      exited_clients.select(:client_id).distinct.count
    end

    def exited_household_count
      exited_clients.select(:household_id).distinct.count
    end

    def first_time_clients
      entered_clients.first_enrollment
    end

    def first_time_client_count
      first_time_clients.select(:client_id).distinct.count
    end

    def re_entry_clients
      entered_clients.re_entry
    end

    def re_entry_client_count
      re_entry_clients.select(:client_id).distinct.count
    end

    def homeless_project_type_ids
      [1, 2, 4, 8]
    end

    def homeless_project_types
      homeless_project_type_ids.map{|m| HUD.project_type(m)}
    end

    def census_by_project_type
      data = Hash[homeless_project_type_ids.zip()]
      counts = enrolled_clients.group(:year, :month, :project_type).
        order(year: :asc, month: :asc).
        distinct(:client_id).count
      homeless_project_type_ids.each do |project_type_id|
        months.reverse.each do |year, month|
          data[project_type_id] ||= [HUD.project_type(project_type_id)]
          data[project_type_id] << counts[[year, month, project_type_id]]
        end
      end
      return data.values.unshift(month_x_axis_labels)
    end

    def months_strings
      months_in_dates.map{|m| m.strftime('%b %Y')}.reverse
    end

    def month_x_axis_labels
      ['x'] + months_strings
    end

    def entry_re_entry_data
      data = {new: [:New], returning: [:Returning]}
      new_entries = first_time_clients.group(:year, :month).
        order(year: :asc, month: :asc).
        distinct(:client_id).count
      returning_entries = re_entry_clients.group(:year, :month).
        order(year: :asc, month: :asc).
        distinct(:client_id).count
      months.reverse.each do |year, month|
        data[:new] << (new_entries[[year, month]] || 0)
        data[:returning] << (returning_entries[[year, month]] || 0)
      end
      return data.values.unshift(month_x_axis_labels)
    end

    # def first_time_entry_locations
    #   data = Hash[homeless_project_type_ids.zip()]
    #   total_counts = first_time_clients.group(:year, :month).distinct(:client_id).count
    #   counts = first_time_clients.group(:year, :month, :project_type).
    #     order(year: :asc, month: :asc).
    #     distinct(:client_id).count
    #   homeless_project_type_ids.each do |project_type_id|
    #     row = {
    #       label: HUD.project_type(project_type_id),
    #     }
    #     months.reverse.each_with_index do |(year, month), i|
    #       row[months_strings[i]] = in_percentage(counts[[year, month, project_type_id]], total_counts[[year, month]])
    #       row["#{months_strings[i]}_count"] = (counts[[year, month, project_type_id]] || 0)

    #     end
    #     data[project_type_id] ||= []
    #     data[project_type_id] << row

    #   end
    #   return data.values
    # end

    def first_time_entry_locations
      data = Hash[homeless_project_type_ids.zip()]
      total_counts = first_time_clients.group(:year, :month).distinct(:client_id).count
      counts = first_time_clients.group(:year, :month, :project_type).
        order(year: :asc, month: :asc).
        distinct(:client_id).count
      homeless_project_type_ids.each do |project_type_id|
        months.reverse.each do |year, month|
          data[project_type_id] ||= [HUD.project_type(project_type_id)]
          data[project_type_id] << in_percentage(counts[[year, month, project_type_id]], total_counts[[year, month]])
        end
      end
      return data.values.unshift(month_x_axis_labels)
    end

    def re_entry_locations
      data = Hash[homeless_project_type_ids.zip()]
      total_counts = re_entry_clients.group(:year, :month).distinct(:client_id).count
      counts = re_entry_clients.group(:year, :month, :project_type).
        order(year: :asc, month: :asc).
        distinct(:client_id).count
      homeless_project_type_ids.each do |project_type_id|
        months.reverse.each do |year, month|
          data[project_type_id] ||= [HUD.project_type(project_type_id)]
          data[project_type_id] << in_percentage(counts[[year, month, project_type_id]], total_counts[[year, month]])
        end
      end
      return data.values.unshift(month_x_axis_labels)
    end

    def all_housed_clients
      self.class.housed.
        for_organizations(organization_ids).
        for_projects(project_ids)
    end

    def all_housed_client_count
      all_housed_clients.distinct.select(:client_id).count
    end

    def housed_clients
      enrolled_clients.housed
    end

    def housed_client_count
      housed_clients.distinct.select(:client_id).count
    end

    def in_percentage partial, total
      return 0 unless total.present? && total > 0
      ((partial / total.to_f) * 100).round(1) rescue 0
    end

    def housed_by_month
      data = {housed: [:Housed]}
      housed = housed_clients.group(:year, :month).
        order(year: :asc, month: :asc).
        distinct(:client_id).count
      months.reverse.each do |year, month|
        data[:housed] << (housed[[year, month]] || 0)
      end
      return data.values.unshift(month_x_axis_labels)
    end

  end
end