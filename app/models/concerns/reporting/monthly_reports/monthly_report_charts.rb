###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::MonthlyReports::MonthlyReportCharts # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern
  included do
    attr_accessor :organization_ids
    attr_accessor :project_ids
    attr_accessor :months
    attr_accessor :project_types
    attr_accessor :filter

    # accepts an array of months in the format:
    # [[year, month], [year, month]]
    scope :in_months, ->(months) do
      return none unless months.present?

      months.sort_by! { |y, m| Date.new(y, m, 15) }
      start_date = Date.new(months.first[0], months.first[1], 1)
      end_date = Date.new(months.last[0], months.last[1], -1)

      where(mid_month: start_date..end_date)
      # ors = months.map do |year, month|
      #   arel_table[:year].eq(year).and(arel_table[:month].eq(month)).to_sql
      # end
      # where(ors.join(' OR '))
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
      where(destination_id: ::HUD.permanent_destinations)
    end

    scope :for_organizations, ->(organization_ids) do
      return all unless organization_ids.present?

      where(organization_id: organization_ids)
    end

    scope :for_projects, ->(project_ids) do
      return all unless project_ids.present?

      where(project_id: project_ids)
    end

    scope :for_project_types, ->(project_types) do
      return all unless project_types.present?

      project_type_codes = []
      project_types.each do |type|
        project_type_codes += GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.try(:[], type)
      end
      where(project_type: project_type_codes)
    end

    scope :heads_of_household, -> do
      where(head_of_household: 1)
    end

    scope :filtered, ->(filter) do
      return all if filter.nil?

      client_ids = GrdaWarehouse::Vispdat::Base.completed.distinct.pluck(:client_id)
      client_ids += GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).merge(
        GrdaWarehouse::HmisForm.vispdat.where.not(vispdat_total_score: nil),
      ).distinct.pluck(:id)
      return where.not(client_id: client_ids) if filter[:vispdat].presence == :without_vispdat
      return where(client_id: client_ids) if filter[:vispdat].presence == :with_vispdat

      return all
    end

    private def cache_key_for_report
      [
        self.class.name,
        organization_ids,
        project_ids,
        months,
        project_types,
        filter,
      ]
    end

    def months_in_dates
      @months_in_dates ||= months.map { |year, month| Date.new(year, month, 1) }
    end

    def clients_for_report
      @clients_for_report ||= self.class.in_months(months).
        for_organizations(organization_ids).
        for_projects(project_ids).
        for_project_types(project_types).
        filtered(filter)
    end

    def enrolled_clients
      clients_for_report.enrolled
    end

    def enrolled_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        enrolled_clients.select(:client_id).distinct.count
      end
    end

    # NOTE: HMIS households (household_id) are different for every enrollment
    # This uses a proxy of only counting heads of household for household ids that
    # meet the scope.
    # Potentially this introduces errors since someone may actually be
    # The head of household in more than one household
    def enrolled_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        self.class.enrolled.in_months(months).
          where(household_id: enrolled_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def active_clients
      clients_for_report.active
    end

    def active_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        active_clients.select(:client_id).distinct.count
      end
    end

    def active_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        self.class.enrolled.in_months(months).
          where(household_id: active_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def entered_clients
      active_clients.entered
    end

    def entered_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        entered_clients.select(:client_id).distinct.count
      end
    end

    def entered_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        self.class.enrolled.in_months(months).
          where(household_id: entered_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def exited_clients
      clients_for_report.exited
    end

    def exited_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        exited_clients.select(:client_id).distinct.count
      end
    end

    def exited_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        self.class.enrolled.in_months(months).
          where(household_id: exited_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def first_time_clients
      entered_clients.first_enrollment
    end

    def first_time_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        first_time_clients.select(:client_id).distinct.count
      end
    end

    def re_entry_clients
      entered_clients.re_entry
    end

    def re_entry_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        re_entry_clients.select(:client_id).distinct.count
      end
    end

    def homeless_project_type_ids
      [1, 2, 4, 8].freeze
    end

    def homeless_project_types
      homeless_project_type_ids.map { |m| HUD.project_type(m) }
    end

    def census_by_project_type
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        data = Hash[homeless_project_type_ids.zip]
        counts = active_clients.group(:year, :month, :project_type).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        homeless_project_type_ids.each do |project_type_id|
          months.each do |year, month|
            data[project_type_id] ||= [HUD.project_type(project_type_id)]
            data[project_type_id] << counts[[year, month, project_type_id]]
          end
        end
        data.values.unshift(month_x_axis_labels)
      end
    end

    def census_by_month
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        data = {}
        totals = active_clients.group(:year, :month).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        months.each do |year, month|
          data['totals'] ||= ['Total']
          data['totals'] << totals[[year, month]]
        end
        data.values.unshift(month_x_axis_labels)
      end
    end

    def months_strings
      months_in_dates.map { |m| m.strftime('%b %Y') }.reverse
    end

    def month_x_axis_labels
      ['x'] + months_strings
    end

    def entry_re_entry_data
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        data = { new: [:New], returning: [:Returning] }
        new_entries = first_time_clients.group(:year, :month).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        returning_entries = re_entry_clients.group(:year, :month).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        months.each do |year, month|
          new_count = (new_entries[[year, month]] || 0)
          returning_count = (returning_entries[[year, month]] || 0)
          data[:new] << new_count
          data[:returning] << returning_count
        end
        data.values.unshift(month_x_axis_labels)
      end
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
    #     months.each_with_index do |(year, month), i|
    #       row[months_strings[i]] = in_percentage(counts[[year, month, project_type_id]], total_counts[[year, month]])
    #       row["#{months_strings[i]}_count"] = (counts[[year, month, project_type_id]] || 0)

    #     end
    #     data[project_type_id] ||= []
    #     data[project_type_id] << row

    #   end
    #   return data.values
    # end

    def first_time_entry_locations
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        data = Hash[homeless_project_type_ids.zip]
        total_counts = first_time_clients.group(:year, :month).select(:client_id).distinct.count
        counts = first_time_clients.group(:year, :month, :project_type).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        homeless_project_type_ids.each do |project_type_id|
          months.each do |year, month|
            data[project_type_id] ||= [HUD.project_type(project_type_id)]
            data[project_type_id] << in_percentage(counts[[year, month, project_type_id]], total_counts[[year, month]])
          end
        end

        data.values.unshift(month_x_axis_labels)
      end
    end

    def re_entry_locations
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        data = Hash[homeless_project_type_ids.zip]
        total_counts = re_entry_clients.group(:year, :month).select(:client_id).distinct.count
        counts = re_entry_clients.group(:year, :month, :project_type).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        homeless_project_type_ids.each do |project_type_id|
          months.each do |year, month|
            data[project_type_id] ||= [HUD.project_type(project_type_id)]
            data[project_type_id] << in_percentage(counts[[year, month, project_type_id]], total_counts[[year, month]])
          end
        end
        data.values.unshift(month_x_axis_labels)
      end
    end

    def all_housed_clients
      self.class.housed
    end

    def all_housed_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        all_housed_clients.select(:client_id).distinct.count
      end
    end

    def housed_clients
      exited_clients.housed
    end

    def housed_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        housed_clients.select(:client_id).distinct.count
      end
    end

    def in_percentage(partial, total)
      return 0 unless total.present? && total.positive?

      begin
        ((partial / total.to_f) * 100).round(1)
      rescue StandardError
        0
      end
    end

    def housed_by_month
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: 4.hours) do
        data = { housed: [:Housed] }
        housed = housed_clients.group(:year, :month).
          order(year: :asc, month: :asc).
          select(:client_id).distinct.count
        months.each do |year, month|
          data[:housed] << (housed[[year, month]] || 0)
        end
        data.values.unshift(month_x_axis_labels)
      end
    end
  end
end
