###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates concurrent (overlapping) enrollments for a client alongside their
    # primary enrollment. Typical use cases: Street Outreach contacts, Services Only
    # case management that runs parallel to housing enrollments.
    #
    # For each slot (0..count-1):
    #   - Picks a project from projects_config weighted by selection_weight
    #   - Creates Hmis::Hud::Enrollment in that project
    #   - Samples the duration distribution → sets exit_on on the state record
    #   - Creates HmisSimulation::ConcurrentEnrollment state record
    class ConcurrentEnrollmentBuilder < BaseBuilder
      def initialize(client:, date:, projects_config:, count:, coc_code:, data_source:, user_id:, rng_seed:, track_name: nil, id_generator: FakeIdentifier)
        super(data_source: data_source, user_id: user_id, id_generator: id_generator)
        @client     = client
        @date       = date
        @projects   = (projects_config || []).map(&:deep_stringify_keys)
        @count      = count.to_i
        @coc_code   = coc_code
        @rng_seed   = rng_seed
        @track_name = track_name
      end

      # Returns an array of the Hmis::Hud::Enrollment records created so the engine
      # can create linked entry records for each.
      def build!
        return [] if @count.zero? || @projects.empty?

        @count.times.filter_map do |slot|
          proj_cfg = pick_project(slot)
          next unless proj_cfg

          project = find_project(proj_cfg['name'])
          next unless project

          enrollment = create_enrollment(project)
          duration   = sample_duration(proj_cfg, slot)

          ConcurrentEnrollment.create!(
            data_source_id: @ds.id,
            hud_client_id: @client.id,
            hud_enrollment_id: enrollment.id,
            project_name: proj_cfg['name'],
            track_name: @track_name,
            exit_on: @date + duration,
          )

          enrollment
        end
      end

      private

      def pick_project(slot)
        return @projects.first if @projects.size == 1

        weights = @projects.each_with_object({}) { |p, h| h[p['name']] = p['selection_weight'].to_f }
        cfg = { 'distribution' => 'weighted', 'weights' => weights }
        name = Distribution.sample(cfg, rng: Random.new(@rng_seed + slot))
        @projects.find { |p| p['name'] == name }
      end

      def find_project(name)
        Hmis::Hud::Project.find_by(data_source_id: @ds.id, ProjectName: name)
      end

      def create_enrollment(project)
        create_solo_enrollment(
          client: @client,
          project: project,
          date: @date,
          coc_code: @coc_code,
          date_of_engagement: (@date if project.ProjectType == 4),
        )
      end

      def sample_duration(proj_cfg, slot)
        duration_cfg = proj_cfg['duration'] || { 'distribution' => 'constant', 'value' => 30 }
        raw = Distribution.sample(duration_cfg.deep_stringify_keys, rng: Random.new(@rng_seed + slot + 100))
        [raw.ceil, 1].max
      end
    end
  end
end
