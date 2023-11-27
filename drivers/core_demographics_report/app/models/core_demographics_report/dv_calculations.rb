###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::DvCalculations
  extend ActiveSupport::Concern
  included do
    def dv_detail_hash
      {}.tap do |hashes|
        HudUtility2024.no_yes_reasons_for_missing_data_options.each do |key, title|
          hashes["dv_#{key}"] = {
            title: "DV Response #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_dv(key)).distinct },
          }
        end
        ::HudUtility2024.when_occurreds.each do |key, title|
          hashes["dv_occurrence_#{key}"] = {
            title: "DV Occurrence Timing #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_dv_occurrence(key)).distinct },
          }
        end
      end
    end

    def dv_occurrence_count(type)
      mask_small_population(dv_occurrence_breakdowns[type]&.count&.presence || 0)
    end

    def dv_occurrence_percentage(type)
      total_count = mask_small_population(client_dv_occurrences.count)
      return 0 if total_count.zero?

      of_type = dv_occurrence_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def dv_occurrence_breakdowns
      @dv_occurrence_breakdowns ||= client_dv_occurrences.group_by do |_, v|
        v
      end
    end

    def client_ids_in_dv_occurrence(type)
      dv_occurrence_breakdowns[type]&.map(&:first)
    end

    private def client_dv_occurrences
      @client_dv_occurrences ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(enrollment: :health_and_dvs).order(hdv_t[:InformationDate].desc).
            merge(
              GrdaWarehouse::Hud::HealthAndDv.where(
                InformationDate: @filter.range,
                DomesticViolenceSurvivor: 1,
              ),
            ).
            distinct.
            pluck(:client_id, hdv_t[:WhenOccurred], hdv_t[:InformationDate]).
            each do |client_id, when_occurred, _|
              clients[client_id] ||= when_occurred
            end
        end
      end
    end

    def dv_status_count(type)
      mask_small_population(dv_status_breakdowns[type]&.count&.presence || 0)
    end

    def dv_status_percentage(type)
      total_count = mask_small_population(client_dv_stati.count)
      return 0 if total_count.zero?

      of_type = dv_status_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def dv_status_data_for_export(rows)
      rows['_DV Victim/Survivor Break'] ||= []
      rows['*DV Victim/Survivor'] ||= []
      rows['*DV Response'] ||= []
      rows['*DV Response'] += ['Response', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.no_yes_reasons_for_missing_data_options.each do |id, title|
        rows["_DV Response_data_#{title}"] ||= []
        rows["_DV Response_data_#{title}"] += [
          title,
          nil,
          dv_status_count(id),
          dv_status_percentage(id) / 100,
        ]
      end
      rows['*DV Victim/Survivor - Most Recent Occurrence'] ||= []
      rows['*DV Occurrence Timing'] ||= []
      rows['*DV Occurrence Timing'] += ['Timing', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.when_occurreds.each do |id, title|
        rows["_DV Occurrence Timing_data_#{title}"] ||= []
        rows["_DV Occurrence Timing_data_#{title}"] += [
          title,
          nil,
          dv_occurrence_count(id),
          dv_occurrence_percentage(id) / 100,
        ]
      end
      rows
    end

    private def dv_status_breakdowns
      @dv_status_breakdowns ||= client_dv_stati.group_by do |_, v|
        v
      end
    end

    def client_ids_in_dv(type)
      dv_status_breakdowns[type]&.map(&:first)
    end

    private def client_dv_stati
      @client_dv_stati ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(enrollment: :health_and_dvs).order(hdv_t[:InformationDate].desc).
            merge(GrdaWarehouse::Hud::HealthAndDv.where(InformationDate: @filter.range)).
            distinct.
            pluck(:client_id, hdv_t[:DomesticViolenceSurvivor], hdv_t[:InformationDate]).
            each do |client_id, status, _|
              clients[client_id] ||= status
            end
        end
      end
    end
  end
end
