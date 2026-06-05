###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  # Validates a simulation configuration hash.
  #
  # Runs JSON Schema validation first (structural + type checks), then
  # applies semantic checks that cannot be expressed in a schema:
  #   - project_ref values resolve to a project in organizations
  #   - transition from/to names exist in the same primary track's populations
  #   - lifecycle trigger_populations name a population in any primary track
  #   - applies_to_tracks values name defined primary tracks
  #   - each primary track has at least one population with entry_point > 0
  #   - at least one track has type "primary"
  #
  # Usage:
  #   v = HmisSimulation::ConfigValidator.new(config)
  #   puts v.errors.join("\n") unless v.valid?
  class ConfigValidator
    attr_reader :errors

    def initialize(config)
      @config = config.deep_stringify_keys
      @errors = []
    end

    def valid?
      @errors = []
      reset_memos!

      schema_errors = HmisSimulation::JsonValidator.perform(@config)
      if schema_errors.any?
        @errors.concat(schema_errors)
        return false
      end

      validate_primary_track_exists
      validate_entry_points
      validate_project_refs
      validate_transitions
      validate_lifecycle_tracks
      validate_concurrent_tracks
      validate_applies_to_tracks

      @errors.empty?
    end

    private

    def reset_memos!
      @primary_tracks = nil
      @concurrent_tracks = nil
      @lifecycle_tracks = nil
      @all_project_names = nil
    end

    def validate_primary_track_exists
      return if primary_tracks.any?

      @errors << 'at least one track with type "primary" is required'
    end

    def validate_entry_points
      primary_tracks.each do |track|
        pops = track['populations'] || []
        next if pops.any? { |p| p['entry_point'].to_f.positive? }

        @errors << "primary track #{track['name'].inspect} must have at least one population with entry_point > 0"
      end
    end

    def validate_project_refs
      project_names = all_project_names

      primary_tracks.each do |track|
        (track['populations'] || []).each do |pop|
          ref = pop['project_ref']
          next if ref.blank? || project_names.include?(ref)

          @errors << "primary track #{track['name'].inspect} population #{pop['name'].inspect} " \
                     "has project_ref #{ref.inspect} that does not match any project name"
        end
      end
    end

    def validate_transitions
      primary_tracks.each do |track|
        pop_names = (track['populations'] || []).map { |p| p['name'] }.to_set

        (track['transitions'] || []).each do |t|
          from = t['from']
          to   = t['to']

          unless pop_names.include?(from)
            @errors << "primary track #{track['name'].inspect} transition from=#{from.inspect} " \
                       'does not name a population in this track'
          end

          unless pop_names.include?(to)
            @errors << "primary track #{track['name'].inspect} transition to=#{to.inspect} " \
                       'does not name a population in this track'
          end
        end
      end
    end

    def validate_lifecycle_tracks
      all_pop_names = primary_tracks.flat_map { |t| t['populations'] || [] }.map { |p| p['name'] }.to_set
      project_names = all_project_names

      lifecycle_tracks.each do |track|
        (track['trigger_populations'] || []).each do |tp|
          next if all_pop_names.include?(tp)

          @errors << "lifecycle track #{track['name'].inspect} trigger_populations includes " \
                     "#{tp.inspect} which does not name any population in any primary track"
        end

        ref = track['project_ref']
        next if ref.blank? || project_names.include?(ref)

        @errors << "lifecycle track #{track['name'].inspect} has project_ref #{ref.inspect} " \
                   'that does not match any project name'
      end
    end

    def validate_concurrent_tracks
      project_names = all_project_names

      concurrent_tracks.each do |track|
        (track['projects'] || []).each do |project_name|
          next if project_names.include?(project_name)

          @errors << "concurrent track #{track['name'].inspect} references project #{project_name.inspect} " \
                     'that does not match any project name in organizations'
        end
      end
    end

    def validate_applies_to_tracks
      primary_track_names = primary_tracks.map { |t| t['name'] }.to_set

      (concurrent_tracks + lifecycle_tracks).each do |track|
        (track['applies_to_tracks'] || []).each do |referenced_name|
          next if primary_track_names.include?(referenced_name)

          @errors << "track #{track['name'].inspect} applies_to_tracks includes " \
                     "#{referenced_name.inspect} which does not name any primary track"
        end
      end
    end

    def primary_tracks
      @primary_tracks ||= (@config['tracks'] || []).select { |t| t['type'] == 'primary' }
    end

    def concurrent_tracks
      @concurrent_tracks ||= (@config['tracks'] || []).select { |t| t['type'] == 'concurrent' }
    end

    def lifecycle_tracks
      @lifecycle_tracks ||= (@config['tracks'] || []).select { |t| t['type'] == 'lifecycle' }
    end

    def all_project_names
      @all_project_names ||= (@config['organizations'] || []).flat_map do |org|
        (org['projects'] || []).map { |p| p['name'] }
      end.to_set
    end
  end
end
