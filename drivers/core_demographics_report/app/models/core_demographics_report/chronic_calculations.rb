###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::ChronicCalculations
  extend ActiveSupport::Concern
  included do
    def chronic_detail_hash
      {}.tap do |hashes|
        available_chronic_types.invert.each do |key, title|
          hashes["chronic_#{key}"] = {
            title: "Chronic - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: chronic_client_ids(key)).distinct },
          }
        end
      end
    end

    def chronic_count(type, coc_code = base_count_sym)
      mask_small_population(chronic_clients[type][coc_code]&.count&.presence || 0)
    end

    def chronic_percentage(type, coc_code = base_count_sym)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = chronic_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def chronic_data_for_export(rows)
      rows['_Chronic at Entry'] ||= []
      rows['*Chronic at Entry'] ||= []
      rows['*Chronic at Entry'] += ['Chronic at Entry', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Chronic at Entry'] += ["#{coc_code} Client"]
        rows['*Chronic at Entry'] += ["#{coc_code} Percentage"]
      end
      rows['*Chronic at Entry'] += [nil]
      available_chronic_types.invert.each do |id, title|
        rows["_Chronic at Entry_data_#{title}"] ||= []
        rows["_Chronic at Entry_data_#{title}"] += [
          title,
          nil,
          chronic_count(id),
          chronic_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Chronic at Entry_data_#{title}"] += [
            chronic_count(id, coc_code.to_sym),
            chronic_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def chronic_client_ids(key, coc_code = base_count_sym)
      chronic_clients[key][coc_code]
    end

    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    def available_chronic_types
      {
        'Client' => :client,
        'Household' => :household,
        'Adult only Households' => :without_children,
        'Adult and Child Households' => :with_children,
        'Child only Households' => :only_children,
        'Youth Only' => :unaccompanied_youth,
      }
    end

    private def initialize_chronic_client_counts(clients, coc_code = base_count_sym)
      available_chronic_types.invert.each do |key, _|
        clients[key][coc_code] = Set.new
      end
    end

    private def set_chronic_client_counts(clients, client_id, enrollment_id, coc_code = base_count_sym)
      @counted_chronic_clients ||= { base_count_sym => Set.new, specific_coc: Set.new }
      counting_context = if coc_code == base_count_sym then base_count_sym else :specific_coc end
      return if client_id.in?(@counted_chronic_clients[counting_context])

      clients[:client][coc_code] << client_id
      clients[:household][coc_code] << client_id if hoh_client_ids.include?(client_id)
      # These need to use enrollment.id to capture age correctly, but needs the client for summary counts
      clients[:without_children][coc_code] << [enrollment_id, client_id] if without_children.include?(enrollment_id)
      clients[:with_children][coc_code] << [enrollment_id, client_id] if with_children.include?(enrollment_id)
      clients[:only_children][coc_code] << [enrollment_id, client_id] if only_children.include?(enrollment_id)
      clients[:unaccompanied_youth][coc_code] << [enrollment_id, client_id] if unaccompanied_youth.include?(enrollment_id)

      # Note we've seen this client so we only include their earliest enrollment
      @counted_chronic_clients[counting_context] << client_id
    end

    private def chronic_clients
      @chronic_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          # Setup sets to hold client ids with no recent homelessness
          available_chronic_types.invert.each do |id, _|
            clients[id] = {}
          end

          initialize_chronic_client_counts(clients)

          report_scope.distinct.
            joins(enrollment: :ch_enrollment).
            merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
            order(first_date_in_program: :asc). # NOTE: this differs from other calculations, we might want to go back to desc
            pluck(:client_id, :id, :first_date_in_program).
            each do |client_id, enrollment_id, _|
              set_chronic_client_counts(clients, client_id, enrollment_id)
            end

          available_coc_codes.each do |coc_code|
            initialize_chronic_client_counts(clients, coc_code.to_sym)

            report_scope.distinct.in_coc(coc_code: coc_code).
              joins(enrollment: :ch_enrollment).
              merge(GrdaWarehouse::ChEnrollment.chronically_homeless).
              order(first_date_in_program: :asc). # NOTE: this differs from other calculations, we might want to go back to desc
              pluck(:client_id, :id, :first_date_in_program).
              each do |client_id, enrollment_id, _|
                set_chronic_client_counts(clients, client_id, enrollment_id, coc_code.to_sym)
              end
          end
        end
      end
    end
  end
end
