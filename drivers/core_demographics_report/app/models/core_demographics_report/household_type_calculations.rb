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

    def household_type_hoh_count(type)
      hoh_households[type]&.values&.flatten&.count&.presence || 0
    end

    def household_type_hoh_percentage(type)
      total_count = hoh_count
      return 0 if total_count.zero?

      of_type = household_type_hoh_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def household_type_client_count(type)
      client_households[type]&.values&.flatten&.count&.presence || 0
    end

    def household_type_client_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = household_type_client_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def household_type_data_for_export(rows)
      rows['_Household Types'] ||= []
      rows['*Household Types'] ||= []
      rows['*Household Types'] += ['Household Type', nil, 'Count', 'Percentage', nil]
      available_household_types.invert.each do |id, title|
        rows["_Household Types_data_#{title}"] ||= []
        rows["_Household Types_data_#{title}"] += [
          title,
          nil,
          household_type_hoh_count(id),
          household_type_hoh_percentage(id) / 100,
        ]
      end
      rows
    end

    private def enrollment_ids_in_household_type(key)
      client_households[key]&.values&.flatten
    end

    private def hoh_enrollment_ids_in_household_type(key)
      hoh_households[key]&.values&.flatten
    end

    def available_household_types
      @filter.available_household_types.merge('Youth Only' => :unaccompanied_youth, 'Unknown' => :unknown)
    end

    private def calculate_households
      @hoh_enrollments ||= {}
      @households ||= {}

      report_scope.joins(enrollment: :client).preload(enrollment: :client).find_each(batch_size: 100) do |enrollment|
        @hoh_enrollments[enrollment.client_id] = enrollment if enrollment.head_of_household?
        next unless enrollment&.enrollment&.client.present?

        date = [enrollment.entry_date, filter.start_date].max
        age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.enrollment.client.DOB&.to_date)
        @households[get_hh_id(enrollment)] ||= []
        @households[get_hh_id(enrollment)] << {
          client_id: enrollment.client_id,
          enrollment_id: enrollment.id,
          age: age,
          relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
        }.with_indifferent_access
      end
    end

    private def get_hh_id(service_history_enrollment)
      service_history_enrollment.household_id || "#{service_history_enrollment.enrollment_group_id}*HH"
    end

    private def households
      calculate_households if @households.nil?
      @households
    end

    private def hoh_enrollments
      calculate_households if @hoh_enrollments.nil?
      @hoh_enrollments
    end

    private def adult_only_households
      @adult_only_households ||= households.select do |_, enrollments|
        enrollments.all? { |en| en['age'].present? && en['age'] >= 18 }
      end
    end

    private def adult_and_child_households
      @adult_and_child_households ||= households.select do |_, enrollments|
        ages = enrollments.map { |en| en['age'] }.compact
        ages.intersect?((0..17).to_a) && ages.intersect?((18..120).to_a)
      end
    end

    private def child_only_households
      @child_only_households ||= households.select do |_, enrollments|
        enrollments.all? { |en| en['age'].present? && en['age'] < 18 }
      end
    end

    private def unaccompanied_youth_households
      @unaccompanied_youth_households ||= households.select do |_, enrollments|
        enrollments.all? { |en| en['age']&.between?(18, 24) }
      end
    end

    private def unknown_households
      @unknown_households ||= begin
        # Reject any adult & child households, we know their type.
        hhs = households.reject do |_, enrollments|
          ages = enrollments.map { |en| en['age'] }.compact
          ages.intersect?((0..17).to_a) && ages.intersect?((18..120).to_a)
        end
        # Otherwise, if there are any missing ages, then we don't know the household type
        hhs.select do |_, enrollments|
          enrollments.detect { |en| en['age'].blank? }
        end
      end
    end

    private def hoh_client_id_en_id_from_enrollments(enrollments)
      hoh_en = enrollments.detect { |en| en['relationship_to_hoh'] == 1 }
      return nil unless hoh_en

      [hoh_en['client_id'], hoh_en['enrollment_id']]
    end

    private def hoh_households
      @hoh_households ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          clients[:all] = hoh_enrollments.map { |_, en| hoh_client_id_en_id_from_enrollments([en]) }.compact.group_by(&:shift)
          clients[:without_children] = adult_only_households.map { |_, ens| hoh_client_id_en_id_from_enrollments(ens) }.compact.group_by(&:shift)
          clients[:with_children] = adult_and_child_households.map { |_, ens| hoh_client_id_en_id_from_enrollments(ens) }.compact.group_by(&:shift)
          clients[:only_children] = child_only_households.map { |_, ens| hoh_client_id_en_id_from_enrollments(ens) }.compact.group_by(&:shift)
          clients[:unaccompanied_youth] = unaccompanied_youth_households.map { |_, ens| hoh_client_id_en_id_from_enrollments(ens) }.compact.group_by(&:shift)
          clients[:unknown] = unknown_households.map { |_, ens| hoh_client_id_en_id_from_enrollments(ens) }.compact.group_by(&:shift)
        end
      end
    end

    private def client_households
      @client_households ||= Rails.cache.fetch(household_types_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          clients[:all] = households.values.map { |enrollments| enrollments&.flat_map { |en| [en['client_id'], en['enrollment_id']] } }&.group_by(&:shift)
          clients[:without_children] = adult_only_households.values.map { |enrollments| enrollments&.flat_map { |en| [en['client_id'], en['enrollment_id']] } }&.group_by(&:shift)
          clients[:with_children] = adult_and_child_households.values.map { |enrollments| enrollments&.flat_map { |en| [en['client_id'], en['enrollment_id']] } }&.group_by(&:shift)
          clients[:only_children] = child_only_households.values.map { |enrollments| enrollments&.flat_map { |en| [en['client_id'], en['enrollment_id']] } }&.group_by(&:shift)
          clients[:unaccompanied_youth] = unaccompanied_youth_households.values.map { |enrollments| enrollments&.flat_map { |en| [en['client_id'], en['enrollment_id']] } }&.group_by(&:shift)
          clients[:unknown] = unknown_households.values.map { |enrollments| enrollments&.flat_map { |en| [en['client_id'], en['enrollment_id']] } }&.group_by(&:shift)
        end
      end
    end

    private def household_types_cache_key
      [self.class.name, cache_slug, 'client_households']
    end
  end
end
