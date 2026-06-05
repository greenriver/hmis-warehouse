###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Validates the structural integrity of a simulation configuration hash.
  # Used by the validate rake task and at the start of bootstrap/run to
  # surface problems before any records are written.
  #
  # Usage:
  #   v = HmisSimulation::ConfigValidator.new(config)
  #   if v.valid?
  #     # proceed
  #   else
  #     puts v.errors.join("\n")
  #   end
  class ConfigValidator
    attr_reader :errors

    def initialize(config)
      @config = config.deep_stringify_keys
      @errors = []
    end

    def valid?
      @errors = []
      validate_top_level
      validate_project_refs
      validate_transitions
      validate_entry_points
      validate_lifecycle_trigger_populations
      validate_concurrent_project_refs
      @errors.empty?
    end

    private

    def validate_top_level
      @errors << 'data_source_id must be a positive integer' unless @config['data_source_id'].to_i.positive?
      @errors << 'seed is required' unless @config.key?('seed')
      @errors << 'name is required' if @config['name'].blank?
      @errors << 'coc_codes.primary is required' if @config.dig('coc_codes', 'primary').blank?
      @errors << 'organizations must be a non-empty array' unless @config['organizations'].is_a?(Array) && @config['organizations'].any?
      @errors << 'populations must be a non-empty array' unless @config['populations'].is_a?(Array) && @config['populations'].any?
    end

    def validate_project_refs
      project_names = all_project_names
      all_population_names

      @config['populations']&.each do |pop|
        ref = pop['project_ref']
        next if ref.blank?
        next if project_names.include?(ref)

        @errors << "population #{pop['name'].inspect} has project_ref #{ref.inspect} that does not match any project name"
      end
    end

    def validate_transitions
      population_names = all_population_names

      @config['transitions']&.each do |t|
        from = t['from']
        to   = t['to']

        @errors << "transition from=#{from.inspect} does not match any defined population" unless population_names.include?(from)
        @errors << "transition to=#{to.inspect} does not match any defined population" unless population_names.include?(to)
      end
    end

    def validate_entry_points
      pops = @config['populations'] || []
      return if pops.any? { |p| p['entry_point'].to_f.positive? }

      @errors << 'at least one population must have entry_point > 0'
    end

    def validate_lifecycle_trigger_populations
      population_names = all_population_names

      @config['lifecycle_enrollments']&.each do |lc|
        lc['trigger_populations']&.each do |tp|
          next if population_names.include?(tp)

          @errors << "lifecycle_enrollment #{lc['name'].inspect} trigger_populations includes #{tp.inspect} which does not match any defined population"
        end

        ref = lc['project_ref']
        @errors << "lifecycle_enrollment #{lc['name'].inspect} has project_ref #{ref.inspect} that does not match any project name" if ref.present? && !all_project_names.include?(ref)
      end
    end

    def validate_concurrent_project_refs
      project_names = all_project_names

      @config.dig('concurrent_enrollments', 'projects')&.each do |p|
        ref = p['name']
        next if project_names.include?(ref)

        @errors << "concurrent_enrollments project #{ref.inspect} does not match any project name in organizations"
      end
    end

    def all_project_names
      @all_project_names ||= (@config['organizations'] || []).flat_map do |org|
        (org['projects'] || []).map { |p| p['name'] }
      end.to_set
    end

    def all_population_names
      @all_population_names ||= (@config['populations'] || []).map { |p| p['name'] }.to_set
    end
  end
end
