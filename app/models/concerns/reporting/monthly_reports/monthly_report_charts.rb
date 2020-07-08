###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::MonthlyReports::MonthlyReportCharts
  extend ActiveSupport::Concern
  included do
    attr_accessor :organization_ids
    attr_accessor :project_ids
    attr_accessor :months
    attr_accessor :project_types
    attr_accessor :filter
    attr_accessor :age_ranges

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
      return current_scope if filter.nil?

      client_ids = warehouse_vispdat_client_ids
      client_ids += hmis_vispdat_client_ids
      client_scope = current_scope
      if filter[:vispdat].presence == :without_vispdat
        client_scope = client_scope.where.not(client_id: client_ids)
      elsif filter[:vispdat].presence == :with_vispdat
        client_scope = where(client_id: client_ids)
      end

      client_scope = client_scope.heads_of_household if filter[:heads_of_household]
      client_scope = client_scope.filter_for_age(filter[:age_ranges])

      client_scope
    end

    def self.filter_for_age(age_ranges)
      return current_scope unless age_ranges&.compact.present?

      age_exists = r_monthly_t[:age_at_entry].not_eq(nil)
      age_ors = []
      age_ors << r_monthly_t[:age_at_entry].lt(18) if age_ranges.include?(:under_eighteen)
      age_ors << r_monthly_t[:age_at_entry].gteq(18).and(r_monthly_t[:age_at_entry].lteq(24)) if age_ranges.include?(:eighteen_to_twenty_four)
      age_ors << r_monthly_t[:age_at_entry].gteq(25).and(r_monthly_t[:age_at_entry].lteq(61)) if age_ranges.include?(:twenty_five_to_sixty_one)
      age_ors << r_monthly_t[:age_at_entry].gt(61) if age_ranges.include?(:over_sixty_one)

      accumulative = nil
      age_ors.each do |age|
        accumulative = if accumulative.present?
          accumulative.or(age)
        else
          age
        end
      end

      current_scope.where(age_exists.and(accumulative))
    end

    def self.warehouse_vispdat_client_ids
      GrdaWarehouse::Hud::Client.destination.joins(:vispdats).merge(GrdaWarehouse::Vispdat::Base.completed).distinct.pluck(:id)
    end

    def self.hmis_vispdat_client_ids
      GrdaWarehouse::Hud::Client.destination.
        joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.vispdat).
        distinct.
        pluck(:id)
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
          # data['totals'] ||= ['Total']
          data['totals'] ||= []
          data['totals'] << totals[[year, month]]
        end
        data['totals'].unshift('Total')
        data.values.unshift(month_x_axis_labels)
      end
    end

    def months_strings
      months_in_dates.map { |m| m.strftime('%b %Y') }
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
    #     months.reverse_each_with_index do |(year, month), i|
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
