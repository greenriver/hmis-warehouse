###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::HighAcuityCalculations
  extend ActiveSupport::Concern
  included do
    def high_acuity_detail_hash
      {}.tap do |hashes|
        available_high_acuity_types.invert.each do |key, title|
          hashes["high_acuity_#{key}"] = {
            title: "High Acuity - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: high_acuity_client_ids(key)).distinct },
          }
        end
      end
    end

    def high_acuity_count(type, coc = base_count_sym)
      mask_small_population(high_acuity_clients[type][coc]&.count&.presence || 0)
    end

    def high_acuity_percentage(type, coc_code = base_count_sym)
      total_count = total_client_count
      # We want the percentage based on the total high acuity households for the hh breakdowns
      total_count = high_acuity_count(:household, coc_code) unless type.in?([:client, :household])
      # Clients with one disability should use clients in the category as a denominator
      total_count = high_acuity_count(:client, coc_code) if type == :one_disability
      return 0 if total_count.zero?

      of_type = high_acuity_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def high_acuity_data_for_export(rows)
      rows['_High Acuity Type'] ||= []
      rows['*High Acuity Type'] ||= []
      rows['*High Acuity Type'] += ['High Acuity Type', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*High Acuity Type'] += ["#{coc_code} Client"]
        rows['*High Acuity Type'] += ["#{coc_code} Percentage"]
      end
      rows['*High Acuity Type'] += [nil]
      available_high_acuity_types.invert.each do |id, title|
        rows["_High Acuity Type_data_#{title}"] ||= []
        rows["_High Acuity Type_data_#{title}"] += [
          title,
          nil,
          high_acuity_count(id),
          high_acuity_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_High Acuity Type_data_#{title}"] += [
            high_acuity_count(id, coc_code.to_sym),
            high_acuity_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def high_acuity_client_ids(key, coc_code = base_count_sym)
      # These two are stored as client_ids, the remaining are enrollment, client_id pairs
      if key.in?([:client, :household, :one_disability])
        high_acuity_clients[key][coc_code]
      else
        # fetch client_ids from Set[[enrollment_id, client_id]]
        high_acuity_clients[key][coc_code].to_a.map(&:last).uniq
      end
    end

    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    def available_high_acuity_types
      {
        'Client' => :client,
        'Household' => :household,
        'Adult only Households' => :without_children,
        'Adult and Child Households' => :with_children,
        'Child only Households' => :only_children,
        'Youth only Households' => :unaccompanied_youth,
        'Clients with only 1 Disability' => :one_disability,
      }
    end

    private def initialize_high_acuity_client_counts(clients, coc_code = base_count_sym)
      available_high_acuity_types.invert.each do |key, _|
        clients[key][coc_code] = Set.new
      end
    end

    private def set_high_acuity_client_counts(clients, client_id, enrollment_id, coc_code = base_count_sym)
      # Only count HoH for household counts, and only count them in one category.
      if !clients[:client][coc_code].include?(client_id) && hoh_client_ids.include?(client_id)
        # These need to use enrollment.id to capture age correctly, but needs the client for summary counts
        clients[:without_children][coc_code] << [enrollment_id, client_id] if without_children.include?(enrollment_id)
        clients[:with_children][coc_code] << [enrollment_id, client_id] if with_children.include?(enrollment_id)
        clients[:only_children][coc_code] << [enrollment_id, client_id] if only_children.include?(enrollment_id)
        clients[:unaccompanied_youth][coc_code] << [enrollment_id, client_id] if unaccompanied_youth.include?(enrollment_id)
      end
      # Always add them to the clients category
      clients[:client][coc_code] << client_id
      clients[:household][coc_code] << client_id if hoh_client_ids.include?(client_id)
    end

    private def high_acuity_clients
      @high_acuity_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          # Setup sets to hold client ids with no recent homelessness
          available_high_acuity_types.invert.each do |key, _|
            clients[key] = {}
          end

          initialize_high_acuity_client_counts(clients)

          report_scope.distinct.
            joins(client: :source_enrollment_disabilities).
            merge(GrdaWarehouse::Hud::Disability.chronically_disabled).
            pluck(:client_id, :id, e_t[:TimesHomelessPastThreeYears], e_t[:DisablingCondition], d_t[:DisabilityType], d_t[:DisabilityResponse], d_t[:IndefiniteAndImpairs]).
            group_by { |e| [e.shift, e.shift, e.shift, e.shift] }.
            each do |(client_id, enrollment_id, times_homeless, disabling_condition), disabilities|
              # Exclude 8, 9, & 99 responses. Assume this enrollment consitutes 1 episode
              next if times_homeless.nil? || times_homeless > 4
              # Don't count anyone we've already counted in the chronic counts
              next if chronic_clients[:client].include?(client_id)

              counted_disabilities = Set.new
              disabilities.each do |d_type, response, indefinite|
                next unless response.in?(GrdaWarehouse::Hud::Disability.positive_responses)

                # developmental and hiv are always indefinite and impairing
                if d_type.in?([6, 8])
                  counted_disabilities << d_type
                elsif indefinite == 1
                  counted_disabilities << d_type
                end
              end
              # Only count disabling condition if there are no supporting disability details
              counted_disabilities << :disabling_condition if disabling_condition == 1 && counted_disabilities.count.zero?

              clients[:one_disability][base_count_sym] << client_id if counted_disabilities.count == 1

              # Don't count anyone with only one disabling condition
              next unless counted_disabilities.count > 1

              set_high_acuity_client_counts(clients, client_id, enrollment_id)
            end

          available_coc_codes.each do |coc_code|
            initialize_high_acuity_client_counts(clients, coc_code.to_sym)

            report_scope.distinct.in_coc(coc_code: coc_code).
              joins(client: :source_enrollment_disabilities).
              merge(GrdaWarehouse::Hud::Disability.chronically_disabled).
              pluck(:client_id, :id, e_t[:TimesHomelessPastThreeYears], e_t[:DisablingCondition], d_t[:DisabilityType], d_t[:DisabilityResponse], d_t[:IndefiniteAndImpairs]).
              group_by { |e| [e.shift, e.shift, e.shift, e.shift] }.
              each do |(client_id, enrollment_id, times_homeless, disabling_condition), disabilities|
                # Exclude 8, 9, & 99 responses. Assume this enrollment consitutes 1 episode
                next if times_homeless.nil? || times_homeless > 4
                # Don't count anyone we've already counted in the chronic counts
                next if chronic_clients[:client][base_count_sym].include?(client_id)

                counted_disabilities = Set.new
                disabilities.each do |d_type, response, indefinite|
                  next unless response.in?(GrdaWarehouse::Hud::Disability.positive_responses)

                  # developmental and hiv are always indefinite and impairing
                  if d_type.in?([6, 8])
                    counted_disabilities << d_type
                  elsif indefinite == 1
                    counted_disabilities << d_type
                  end
                end
                # Only count disabling condition if there are no supporting disability details
                counted_disabilities << :disabling_condition if disabling_condition == 1 && counted_disabilities.count.zero?

                clients[:one_disability][coc_code.to_sym] << client_id if counted_disabilities.count == 1

                # Don't count anyone with only one disabling condition
                next unless counted_disabilities.count > 1

                set_high_acuity_client_counts(clients, client_id, enrollment_id, coc_code.to_sym)
              end
          end
        end
      end
    end
  end
end
