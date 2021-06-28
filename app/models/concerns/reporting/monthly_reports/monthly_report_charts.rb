###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::MonthlyReports::MonthlyReportCharts
  extend ActiveSupport::Concern
  included do
    attr_accessor :filter, :user

    EXPIRY = if Rails.env.development? then 30.seconds else 4.hours end

    scope :in_months, ->(range) do
      return none unless range.present?

      where(mid_month: range)
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
      where(
        destination_id: ::HUD.permanent_destinations,
        exit_date: Reporting::MonthlyReports::Base.lookback_start..Date.current,
      )
    end

    scope :for_organizations, ->(organization_ids) do
      return all unless organization_ids.present?

      where(organization_id: organization_ids)
    end

    scope :for_projects, ->(project_ids) do
      return all unless project_ids.present?

      where(project_id: project_ids)
    end

    scope :for_project_types, ->(project_types_ids) do
      return all unless project_types_ids.present?

      where(project_type: project_types_ids)
    end

    scope :heads_of_household, -> do
      where(head_of_household: 1)
    end

    scope :filtered, ->(filter) do
      return current_scope if filter.nil?

      client_ids = warehouse_vispdat_client_ids
      client_ids += hmis_vispdat_client_ids
      client_scope = current_scope
      if filter.limit_to_vispdat.presence == :without_vispdat
        client_scope = client_scope.where.not(client_id: client_ids)
      elsif filter.limit_to_vispdat.presence == :with_vispdat
        client_scope = where(client_id: client_ids)
      end

      client_scope = client_scope.heads_of_household if filter.hoh_only
      client_scope = client_scope.filter_for_age(filter.age_ranges)
      client_scope = client_scope.filter_for_coc_codes(filter.coc_codes)
      client_scope = client_scope.filter_for_race(filter.races)
      client_scope = client_scope.filter_for_ethnicity(filter.ethnicities)
      client_scope = client_scope.filter_for_gender(filter.genders)

      client_scope
    end

    def self.filter_for_age(age_ranges)
      return current_scope unless age_ranges&.compact.present?

      age_exists = r_monthly_t[:age_at_entry].not_eq(nil)

      ages = []
      ages += (0..17).to_a if age_ranges.include?(:under_eighteen)
      ages += (18..24).to_a if age_ranges.include?(:eighteen_to_twenty_four)
      ages += (25..29).to_a if age_ranges.include?(:twenty_five_to_twenty_nine)
      ages += (30..39).to_a if age_ranges.include?(:thirty_to_thirty_nine)
      ages += (40..49).to_a if age_ranges.include?(:forty_to_forty_nine)
      ages += (50..59).to_a if age_ranges.include?(:fifty_to_fifty_nine)
      ages += (60..61).to_a if age_ranges.include?(:sixty_to_sixty_one)
      ages += (62..110).to_a if age_ranges.include?(:over_sixty_one)

      current_scope.where(age_exists.and(r_monthly_t[:age_at_entry].in(ages)))
    end

    def self.filter_for_race(races)
      return current_scope unless races&.present?

      keys = races
      race_scope = nil
      race_scope = add_alternative(race_scope, race_alternative(:AmIndAKNative)) if keys.include?('AmIndAKNative')
      race_scope = add_alternative(race_scope, race_alternative(:Asian)) if keys.include?('Asian')
      race_scope = add_alternative(race_scope, race_alternative(:BlackAfAmerican)) if keys.include?('BlackAfAmerican')
      race_scope = add_alternative(race_scope, race_alternative(:NativeHIOtherPacific)) if keys.include?('NativeHIOtherPacific')
      race_scope = add_alternative(race_scope, race_alternative(:White)) if keys.include?('White')
      race_scope = add_alternative(race_scope, race_alternative(:RaceNone)) if keys.include?('RaceNone')

      # Include anyone who has more than one race listed, anded with any previous alternatives
      race_scope ||= current_scope
      race_scope = race_scope.where(id: multi_racial_clients.select(:id)) if keys.include?('MultiRacial')

      current_scope.where(client_id: race_scope.pluck(:id))
    end

    def self.multi_racial_clients
      # Looking at all races with responses of 1, where we have a sum > 1
      columns = [
        c_t[:AmIndAKNative],
        c_t[:Asian],
        c_t[:BlackAfAmerican],
        c_t[:NativeHIOtherPacific],
        c_t[:White],
      ]
      GrdaWarehouse::Hud::Client.
        destination.
        where(Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98))
    end

    def self.add_alternative(scope, alternative)
      if scope.present?
        scope.or(alternative)
      else
        alternative
      end
    end

    def self.race_alternative(key)
      GrdaWarehouse::Hud::Client.destination.where(key => 1)
    end

    def self.filter_for_ethnicity(ethnicities)
      return current_scope unless ethnicities&.present?

      current_scope.where(client_id: GrdaWarehouse::Hud::Client.destination.where(Ethnicity: ethnicities).pluck(:id))
    end

    def self.filter_for_gender(genders)
      return current_scope unless genders&.present?

      current_scope.where(client_id: GrdaWarehouse::Hud::Client.destination.where(Gender: genders).pluck(:id))
    end

    # This needs to check project_id in the warehouse since we don't store this in the reporting DB
    def self.filter_for_coc_codes(coc_codes)
      return current_scope unless coc_codes&.compact.present?

      project_ids = GrdaWarehouse::Hud::Project.in_coc(coc_code: coc_codes).distinct.pluck(:id)

      current_scope.where(project_id: project_ids)
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
        filter.for_params,
      ]
    end

    def clients_for_report
      @clients_for_report ||= self.class.
        where(project_id: GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id)).
        in_months(filter.range).
        for_organizations(filter.organization_ids).
        for_projects(filter.project_ids).
        for_project_types(filter.project_type_ids).
        filtered(filter)
    end

    def enrolled_clients
      clients_for_report.enrolled
    end

    def enrolled_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        enrolled_clients.select(:client_id).distinct.count
      end
    end

    # NOTE: HMIS households (household_id) are different for every enrollment
    # This uses a proxy of only counting heads of household for household ids that
    # meet the scope.
    # Potentially this introduces errors since someone may actually be
    # The head of household in more than one household
    def enrolled_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        self.class.enrolled.in_months(filter.range).
          where(household_id: enrolled_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def active_clients
      clients_for_report.active
    end

    def active_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        active_clients.select(:client_id).distinct.count
      end
    end

    def active_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        self.class.enrolled.in_months(filter.range).
          where(household_id: active_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def entered_clients
      active_clients.entered
    end

    def entered_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        entered_clients.select(:client_id).distinct.count
      end
    end

    def entered_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        self.class.enrolled.in_months(filter.range).
          where(household_id: entered_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def exited_clients
      clients_for_report.exited
    end

    def exited_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        exited_clients.select(:client_id).distinct.count
      end
    end

    def exited_household_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        self.class.enrolled.in_months(filter.range).
          where(household_id: exited_clients.select(:household_id)).
          heads_of_household.select(:client_id).distinct.count
      end
    end

    def first_time_clients
      entered_clients.first_enrollment
    end

    def first_time_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        first_time_clients.select(:client_id).distinct.count
      end
    end

    def re_entry_clients
      entered_clients.re_entry
    end

    def re_entry_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      @months_strings ||= [].tap do |months|
        date = filter.start_date
        while date < filter.end_date
          months << date.strftime('%b %Y')
          date += 1.months
        end
      end
    end

    # for backwards compatability provide months in format [[year, month]]
    def months
      @months ||= [].tap do |months|
        date = filter.start_date
        while date < filter.end_date
          months << [date.year, date.month]
          date += 1.months
        end
      end
    end

    def month_x_axis_labels
      ['x'] + months_strings
    end

    def entry_re_entry_data
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
        all_housed_clients.select(:client_id).distinct.count
      end
    end

    def housed_clients
      exited_clients.housed
    end

    def housed_client_count
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
      Rails.cache.fetch(cache_key_for_report + [__method__], expires_in: EXPIRY) do
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
