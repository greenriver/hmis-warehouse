###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::HouseholdTypeCalculations
  extend ActiveSupport::Concern
  included do
    def household_detail_hash
      {}.tap do |hashes|
        available_household_types.invert.each do |key, title|
          # HoH counts
          hashes["household_type_#{key}"] = {
            title: "Household Type - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(id: hoh_enrollment_ids_in_household_type(key)).distinct },
          }
          # All client counts
          hashes["household_type_client_#{key}"] = {
            title: "Household Type - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(id: enrollment_ids_in_household_type(key)).distinct },
          }
        end
      end
    end

    def household_type_hoh_count(type, coc = base_count_sym)
      mask_small_population(hoh_households(coc)[type]&.keys&.count&.presence || 0)
    end

    def household_type_hoh_percentage(type, coc = base_count_sym)
      total_count = hoh_count
      return 0 if total_count.zero?

      of_type = household_type_hoh_count(type, coc)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def household_type_client_count(type, coc = base_count_sym)
      mask_small_population(client_households(coc)[type]&.keys&.count&.presence || 0)
    end

    def household_type_client_percentage(type, coc = base_count_sym)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = household_type_client_count(type, coc)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def household_type_data_for_export(rows)
      rows['_Household Types'] ||= []
      rows['*Household Types'] ||= []
      rows['*Household Types'] += ['Household Type', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc|
        rows['*Household Types'] += [coc]
      end
      rows['*Household Types'] += [nil]
      available_household_types.invert.each do |id, title|
        rows["_Household Types_data_#{title}"] ||= []
        rows["_Household Types_data_#{title}"] += [
          title,
          nil,
          household_type_hoh_count(id),
          household_type_hoh_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Household Types_data_#{title}"] += [household_type_hoh_count(id, coc_code.to_sym)]
        end
      end
      rows
    end

    private def enrollment_ids_in_household_type(key, coc = base_count_sym)
      client_households(coc)[key]&.values&.flatten
    end

    private def hoh_enrollment_ids_in_household_type(key, coc = base_count_sym)
      hoh_households(coc)[key]&.values&.flatten
    end

    def available_household_types
      @filter.available_household_types.merge('Youth Only' => :unaccompanied_youth, 'Unknown' => :unknown)
    end

    private def calculate_households
      @hoh_enrollments ||= Rails.cache.fetch([self.class.name, cache_slug, "#{__method__}_hoh_enrollments"], expires_in: expiration_length)
      @households ||= Rails.cache.fetch([self.class.name, cache_slug, "#{__method__}_households"], expires_in: expiration_length)

      return unless @hoh_enrollments.nil? && @households.nil?

      @hoh_enrollments ||= {}
      @households ||= {}

      @hoh_enrollments[base_count_sym] = {}
      @households[base_count_sym] = {}

      # Ignore client-specific filters so we can calculate household type based on who was there, not who is available for reporting
      household_scope = filter.apply_project_level_restrictions(report_scope_source)
      # use she.client (destination client) for DOB/Age, sometimes QA has weird data
      set_household_counts(household_scope)

      available_coc_codes.each do |coc_code|
        @hoh_enrollments[coc_code.to_sym] = {}
        @households[coc_code.to_sym] = {}

        # Ignore client-specific filters so we can calculate household type based on who was there, not who is available for reporting
        household_scope = filter.apply_project_level_restrictions(report_scope_source.in_coc(coc_code: coc_code))
        # use she.client (destination client) for DOB/Age, sometimes QA has weird data
        set_household_counts(household_scope, coc_code.to_sym)
      end

      Rails.cache.write([self.class.name, cache_slug, "#{__method__}_hoh_enrollments"], @hoh_enrollments, expires_in: expiration_length)
      Rails.cache.write([self.class.name, cache_slug, "#{__method__}_households"], @households, expires_in: expiration_length)
    end

    private def set_household_counts(household_scope, coc = base_count_sym)
      household_scope.joins(enrollment: :client).preload(:client, enrollment: :client).distinct.find_each(batch_size: 1_000) do |enrollment|
        date = [enrollment.entry_date, filter.start_date].max
        age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.client&.DOB&.to_date)
        en = {
          'client_id' => enrollment.client_id,
          'enrollment_id' => enrollment.id,
          'age' => age,
          'relationship_to_hoh' => enrollment.enrollment.RelationshipToHoH,
        }
        @hoh_enrollments[coc][get_hh_id(enrollment)] = en if enrollment.head_of_household?
        @households[coc][get_hh_id(enrollment)] ||= []
        @households[coc][get_hh_id(enrollment)] << en
      end
    end

    private def get_hh_id(service_history_enrollment)
      "#{service_history_enrollment.household_id}_#{service_history_enrollment.data_source_id}" || "#{service_history_enrollment.enrollment_group_id}_#{service_history_enrollment.data_source_id}*HH"
    end

    private def households(coc = base_count_sym)
      calculate_households if @households.nil? || @households[coc].nil?
      @households[coc]
    end

    private def hoh_enrollments(coc = base_count_sym)
      calculate_households if @hoh_enrollments.nil? || @hoh_enrollments[coc].nil?
      @hoh_enrollments[coc]
    end

    private def adult_only_households(coc = base_count_sym)
      @adult_only_households ||= {}
      @adult_only_households[coc] ||= households(coc).select do |_, enrollments|
        enrollments.all? { |en| en['age'].present? && en['age'] >= 18 }
      end
    end

    private def adult_and_child_households(coc = base_count_sym)
      @adult_and_child_households ||= {}
      @adult_and_child_households[coc] ||= households(coc).select do |_, enrollments|
        ages = enrollments.map { |en| en['age'] }.compact
        ages.intersect?((0..17).to_a) && ages.intersect?((18..120).to_a)
      end
    end

    private def child_only_households(coc = base_count_sym)
      @child_only_households ||= {}
      @child_only_households[coc] ||= households(coc).select do |_, enrollments|
        enrollments.all? { |en| en['age'].present? && en['age'] < 18 }
      end
    end

    private def unaccompanied_youth_households(coc = base_count_sym)
      @unaccompanied_youth_households ||= {}
      @unaccompanied_youth_households[coc] ||= households(coc).select do |_, enrollments|
        enrollments.all? { |en| en['age']&.between?(18, 24) || false }
      end
    end

    private def unknown_households(coc = base_count_sym)
      @unknown_households ||= {}
      @unknown_households[coc] ||= begin
        # Reject any adult & child households, we know their type.
        hhs = households(coc).reject do |_, enrollments|
          ages = enrollments.map { |en| en['age'] }.compact
          ages.intersect?((0..17).to_a) && ages.intersect?((18..120).to_a)
        end
        # Otherwise, if there are any missing ages, then we don't know the household type
        hhs.select do |_, enrollments|
          enrollments.detect { |en| en['age'].blank? }
        end
      end
    end

    private def hoh_households(coc = base_count_sym)
      @hoh_households ||= {}
      # Force calculation of Households if necessary
      hoh_enrollments(coc)
      @hoh_households[coc] ||= Rails.cache.fetch([self.class.name, cache_slug, "#{__method__}_#{coc}"], expires_in: expiration_length) do
        {}.tap do |clients|
          clients[:all] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(hoh_enrollments(coc).values.flatten, hoh_only: true)).group_by(&:shift)
          clients[:without_children] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(adult_only_households(coc).values.flatten, hoh_only: true)).group_by(&:shift)
          clients[:with_children] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(adult_and_child_households(coc).values.flatten, hoh_only: true)).group_by(&:shift)
          clients[:only_children] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(child_only_households(coc).values.flatten, hoh_only: true)).group_by(&:shift)
          clients[:unaccompanied_youth] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(unaccompanied_youth_households(coc).values.flatten, hoh_only: true)).group_by(&:shift)
          clients[:unknown] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(unknown_households(coc).values.flatten, hoh_only: true)).group_by(&:shift)
        end
      end
    end

    private def client_households(coc = base_count_sym)
      @client_households ||= {}
      # Force calculation of Households if necessary
      households(coc)
      @client_households[coc] ||= Rails.cache.fetch(household_types_cache_key(coc), expires_in: expiration_length) do
        {}.tap do |clients|
          clients[:all] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(households(coc).values.flatten))&.group_by(&:shift)
          clients[:without_children] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(adult_only_households(coc).values.flatten))&.group_by(&:shift)
          clients[:with_children] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(adult_and_child_households(coc).values.flatten))&.group_by(&:shift)
          clients[:only_children] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(child_only_households(coc).values.flatten))&.group_by(&:shift)
          clients[:unaccompanied_youth] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(unaccompanied_youth_households(coc).values.flatten))&.group_by(&:shift)
          clients[:unknown] = convert_enrollments_to_client_id_enrollment_id_pairs(filter_enrollments_for_report_scope(unknown_households(coc).values.flatten))&.group_by(&:shift)
        end
      end
    end

    # We need all related household members to calculate the household, but once we know the household type,
    # we only want the enrollments that meet the report filter criteria
    private def filter_enrollments_for_report_scope(enrollments, hoh_only: false)
      enrollments&.select do |en|
        next false if hoh_only && en['relationship_to_hoh'] != 1

        en['enrollment_id'].in?(report_scope_enrollment_ids)
      end
    end

    private def convert_enrollments_to_client_id_enrollment_id_pairs(enrollments)
      enrollments&.map do |en|
        [en['client_id'], en['enrollment_id']]
      end
    end

    private def report_scope_enrollment_ids
      @report_scope_enrollment_ids ||= report_scope.pluck(:id).to_set
    end

    private def household_types_cache_key(coc = base_count_sym)
      [self.class.name, cache_slug, "client_households_#{coc}"]
    end
  end
end
