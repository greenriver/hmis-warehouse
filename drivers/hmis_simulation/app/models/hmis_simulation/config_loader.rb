###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Loads simulation configuration from AppConfigProperty or a JSON file,
  # normalizes relative weights so callers always see values summing to 1.0.
  #
  # Usage:
  #   config = HmisSimulation::ConfigLoader.from_app_config('hmis_simulation/demo-coc')
  #   config = HmisSimulation::ConfigLoader.from_file('config/simulations/samples/small_coc.json')
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
    end

    def upsert_app_config(key, config)
      record = AppConfigProperty.find_or_initialize_by(key: key)
      record.value = config
      record.save!
    end

    # -- private --

    def normalize(config)
      config = config.deep_dup

      normalize_entry_points!(config)
      normalize_transition_weights!(config)
      normalize_exit_destinations!(config)
      normalize_concurrent_selection_weights!(config)

      config
    end

    def normalize_entry_points!(config)
      pops = config['populations']
      return unless pops.present?

      total = pops.sum { |p| p['entry_point'].to_f }
      return if total.zero?

      pops.each { |p| p['entry_point'] = p['entry_point'].to_f / total }
    end

    def normalize_transition_weights!(config)
      transitions = config['transitions']
      return unless transitions.present?

      transitions.group_by { |t| t['from'] }.each_value do |group|
        total = group.sum { |t| t['weight'].to_f }
        next if total.zero?

        group.each { |t| t['weight'] = t['weight'].to_f / total }
      end
    end

    def normalize_exit_destinations!(config)
      transitions = config['transitions']
      return unless transitions.present?

      transitions.each do |t|
        dests = t['exit_destinations']
        next unless dests.present?

        total = dests.values.sum(&:to_f)
        next if total.zero?

        t['exit_destinations'] = dests.transform_values { |w| w.to_f / total }
      end
    end

    def normalize_concurrent_selection_weights!(config)
      projects = config.dig('concurrent_enrollments', 'projects')
      return unless projects.present?

      total = projects.sum { |p| p['selection_weight'].to_f }
      return if total.zero?

      projects.each { |p| p['selection_weight'] = p['selection_weight'].to_f / total }
    end
  end
end
