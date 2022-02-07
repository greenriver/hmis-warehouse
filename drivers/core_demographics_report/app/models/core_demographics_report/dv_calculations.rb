###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::DvCalculations
  extend ActiveSupport::Concern
  included do
    def dv_detail_hash
      {}.tap do |hashes|
        HUD.no_yes_reasons_for_missing_data_options.each do |key, title|
          hashes["dv_#{key}"] = {
            title: "DV Response #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_dv(key)).distinct },
          }
        end
        ::HUD.when_occurreds.each do |key, title|
          hashes["dv_occurrence_#{key}"] = {
            title: "DV Occurrence Timing #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_dv_occurrence(key)).distinct },
          }
        end
      end
    end

    def dv_occurrence_count(type)
      dv_occurrence_breakdowns[type]&.count&.presence || 0
    end

    def dv_occurrence_percentage(type)
      total_count = client_dv_occurrences.count
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
                DomesticViolenceVictim: 1,
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
      dv_status_breakdowns[type]&.count&.presence || 0
    end

    def dv_status_percentage(type)
      total_count = client_dv_stati.count
      return 0 if total_count.zero?

      of_type = dv_status_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def dv_status_data_for_export(rows)
      rows['_DV Victim/Survivor Break'] ||= []
      rows['*DV Victim/Survivor'] ||= []
      rows['*DV Response'] ||= []
      rows['*DV Response'] += ['Count', 'Percentage', nil, nil]
      ::HUD.no_yes_reasons_for_missing_data_options.each do |id, title|
        rows["_DV Response#{title}"] ||= []
        rows["_DV Response#{title}"] += [
          title,
          dv_status_count(id),
          dv_status_percentage(id),
          nil,
        ]
      end
      rows['*DV Victim/Survivor - Most Recent Occurance'] ||= []
      rows['*DV Occurrence Timing'] ||= []
      rows['*DV Occurrence Timing'] += ['Count', 'Percentage', nil, nil]
      ::HUD.when_occurreds.each do |id, title|
        rows["_DV Occurrence Timing#{title}"] ||= []
        rows["_DV Occurrence Timing#{title}"] += [
          title,
          dv_occurrence_count(id),
          dv_occurrence_percentage(id),
          nil,
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
            pluck(:client_id, hdv_t[:DomesticViolenceVictim], hdv_t[:InformationDate]).
            each do |client_id, status, _|
              clients[client_id] ||= status
            end
        end
      end
    end
  end
end
