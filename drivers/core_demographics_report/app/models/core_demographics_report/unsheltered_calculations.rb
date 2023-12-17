###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::UnshelteredCalculations
  extend ActiveSupport::Concern
  included do
    def unsheltered_detail_hash
      {}.tap do |hashes|
        available_unsheltered_types.invert.each do |key, title|
          hashes["unsheltered_#{key}"] = {
            title: "Unsheltered - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: unsheltered_client_ids(key)).distinct },
          }
        end
      end
    end

    def unsheltered_count(type, coc_code = base_count_sym)
      mask_small_population(unsheltered_clients[type][coc_code]&.count&.presence || 0)
    end

    def unsheltered_percentage(type, coc_code = base_count_sym)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = unsheltered_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def unsheltered_data_for_export(rows)
      rows['_Unsheltered'] ||= []
      rows['*Unsheltered'] ||= []
      rows['*Unsheltered'] += ['Unsheltered', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Unsheltered'] += ["#{coc_code} Client"]
        rows['*Unsheltered'] += ["#{coc_code} Percentage"]
      end
      rows['*Unsheltered'] += [nil]
      available_unsheltered_types.invert.each do |id, title|
        rows["_Unsheltered_data_#{title}"] ||= []
        rows["_Unsheltered_data_#{title}"] += [
          title,
          nil,
          unsheltered_count(id),
          unsheltered_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Unsheltered_data_#{title}"] += [
            unsheltered_count(id, coc_code.to_sym),
            unsheltered_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def unsheltered_client_ids(key, coc_code = base_count_sym)
      unsheltered_clients[key][coc_code]
    end

    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    def available_unsheltered_types
      {
        'Client' => :client,
        'Household' => :household,
        'Adult only Households' => :without_children,
        'Adult and Child Households' => :with_children,
        'Child only Households' => :only_children,
        'Youth Only' => :unaccompanied_youth,
      }
    end

    private def initialize_unsheltered_client_counts(clients, coc_code = base_count_sym)
      available_unsheltered_types.invert.each do |key, _|
        clients[key][coc_code] = Set.new
      end
    end

    private def set_unsheltered_client_counts(clients, client_id, enrollment_id, coc_code = base_count_sym)
      # Always add them to the clients category
      clients[:client][coc_code] << client_id
      clients[:household][coc_code] << client_id if hoh_client_ids.include?(client_id)
      # These need to use enrollment.id to capture age correctly, but needs the client for summary counts
      clients[:without_children][coc_code] << [enrollment_id, client_id] if without_children.include?(enrollment_id)
      clients[:with_children][coc_code] << [enrollment_id, client_id] if with_children.include?(enrollment_id)
      clients[:only_children][coc_code] << [enrollment_id, client_id] if only_children.include?(enrollment_id)
      clients[:unaccompanied_youth][coc_code] << [enrollment_id, client_id] if unaccompanied_youth.include?(enrollment_id)
    end

    private def unsheltered_clients
      @unsheltered_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          # Setup sets to hold client ids with no recent homelessness
          available_unsheltered_types.invert.each do |key, _|
            clients[key] = {}
          end

          initialize_unsheltered_client_counts(clients)

          report_scope.distinct.
            in_project_type(HudUtility2024.project_type_number('Street Outreach')).
            # checks SHS which equates to CLS
            with_service_between(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :id, :first_date_in_program).
            each do |client_id, enrollment_id, _|
              set_unsheltered_client_counts(clients, client_id, enrollment_id)
            end
          available_coc_codes.each do |coc_code|
            initialize_unsheltered_client_counts(clients, coc_code.to_sym)

            report_scope.distinct.in_coc(coc_code: coc_code).
              in_project_type(HudUtility2024.project_type_number('Street Outreach')).
              # checks SHS which equates to CLS
              with_service_between(start_date: filter.start_date, end_date: filter.end_date).
              order(first_date_in_program: :desc).
              pluck(:client_id, :id, :first_date_in_program).
              each do |client_id, enrollment_id, _|
                set_unsheltered_client_counts(clients, client_id, enrollment_id, coc_code.to_sym)
              end
          end
        end
      end
    end
  end
end
