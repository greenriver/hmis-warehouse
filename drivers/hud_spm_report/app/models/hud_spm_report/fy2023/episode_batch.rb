###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class EpisodeBatch
    def initialize(enrollments, included_project_types, excluded_project_types, include_self_reported_and_ph, report)
      @enrollments = enrollments
      @included_project_types = included_project_types
      @excluded_project_types = excluded_project_types
      @include_self_reported_and_ph = include_self_reported_and_ph
      @report = report
    end

    def calculate_batch(client_ids)
      enrollments_for_slice = @enrollments.where(client_id: client_ids).preload(:client, enrollment: :services).group_by(&:client_id)
      episodes = []
      bed_nights_per_episode = []
      enrollment_links_per_episode = []
      client_ids.each do |client_id|
        episode_calculations = HudSpmReport::Fy2023::Episode.new(client_id: client_id, report: @report).
          compute_episode(
            enrollments_for_slice[client_id],
            included_project_types: @included_project_types,
            excluded_project_types: @excluded_project_types,
            include_self_reported_and_ph: @include_self_reported_and_ph,
          )
        # Ignore clients with no episode
        next if episode_calculations.blank?

        # Ignore clients with no bed nights in report range
        any_bed_nights_in_report_range = episode_calculations[:any_bed_nights_in_report_range]
        next unless any_bed_nights_in_report_range

        episodes << episode_calculations[:episode]
        bed_nights_per_episode << episode_calculations[:bed_nights]
        enrollment_links_per_episode << episode_calculations[:enrollment_links]
      end

      save_episodes!(episodes, bed_nights_per_episode, enrollment_links_per_episode)

      episodes
    end

    # The associations seem to make imports run one at a time, so, they are passed separately in parallel arrays
    private def save_episodes!(episodes, bed_nights, enrollment_links)
      # Import the episodes
      results = Episode.import!(episodes)
      # Attach the associations to their episode
      results.ids.each_with_index do |id, index|
        bn_for_episode = bed_nights[index]
        bed_nights[index] = bn_for_episode.map do |bn|
          bn.episode_id = id
          bn
        end
        el_for_episode = enrollment_links[index]
        enrollment_links[index] = el_for_episode.map do |el|
          el.episode_id = id
          el
        end
      end
      # Import the associations
      BedNight.import!(bed_nights.flatten)
      EnrollmentLink.import!(enrollment_links.flatten)
    end
  end
end
