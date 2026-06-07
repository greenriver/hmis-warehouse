###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Loads simulation configuration from AppConfigProperty or a JSON file,
  # then normalizes relative weights per-track so callers always receive
  # values that sum to 1.0 within each distribution.
  #
  # Usage:
  #   config = HmisSimulation::ConfigLoader.from_app_config('hmis_simulation/demo-coc')
  #   config = HmisSimulation::ConfigLoader.from_file('drivers/hmis_simulation/config/sample/small_coc.json')
  module ConfigLoader
    module_function

    def from_app_config(key)
      record = AppConfigProperty.find_by(key: key)
      raise KeyError, "AppConfigProperty not found for key: #{key.inspect}" unless record

      normalize(record.value.deep_stringify_keys)
    end

    def from_file(path)
      raw = JSON.parse(File.read(path))
      normalize(raw.deep_stringify_keys)
    rescue Errno::ENOENT => e
      raise KeyError, "Simulation config file not found: #{path} (#{e.message})"
    rescue JSON::ParserError => e
      raise KeyError, "Simulation config file is not valid JSON: #{path} (#{e.message})"
    end

    def upsert_app_config(key, config)
      record = AppConfigProperty.find_or_initialize_by(key: key)
      record.value = config
      record.save!
    end

    # -- private --

    def normalize(config)
      config = config.deep_dup

      (config['tracks'] || []).each do |track|
        case track['type']
        when 'primary'
          normalize_entry_points!(track)
          normalize_transition_weights!(track)
          normalize_exit_destinations!(track)
          normalize_prior_living_situation_weights!(track)
        when 'concurrent'
          normalize_count_distribution!(track)
        end
      end

      config
    end

    def normalize_entry_points!(track)
      pops = track['populations']
      return unless pops.present?

      total = pops.sum { |p| p['entry_point'].to_f }
      return if total.zero?

      pops.each { |p| p['entry_point'] = p['entry_point'].to_f / total }
    end

    def normalize_transition_weights!(track)
      transitions = track['transitions']
      return unless transitions.present?

      transitions.group_by { |t| t['from'] }.each_value do |group|
        total = group.sum { |t| t['weight'].to_f }
        next if total.zero?

        group.each { |t| t['weight'] = t['weight'].to_f / total }
      end
    end

    def normalize_exit_destinations!(track)
      transitions = track['transitions']
      return unless transitions.present?

      transitions.each do |t|
        dests = t['exit_destinations']
        next unless dests.present?

        total = dests.values.sum(&:to_f)
        next if total.zero?

        t['exit_destinations'] = dests.transform_values { |w| w.to_f / total }
      end
    end

    def normalize_prior_living_situation_weights!(track)
      (track['populations'] || []).each do |pop|
        weights = pop.dig('prior_living_situation', 'weights')
        next unless weights.present?

        total = weights.values.sum(&:to_f)
        next if total.zero?

        pop['prior_living_situation']['weights'] = weights.transform_values { |w| w.to_f / total }
      end
    end

    def normalize_count_distribution!(track)
      dist = track['count_distribution']
      return unless dist.present?

      total = dist.values.sum(&:to_f)
      return if total.zero?

      track['count_distribution'] = dist.transform_values { |w| w.to_f / total }
    end
  end
end
