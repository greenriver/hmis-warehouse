###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class EpisodeBatch
    def initialize(enrollments, included_project_types, excluded_project_types, include_self_reported_and_ph, report)
      @enrollments = enrollments # are SpmEnrollment
      @included_project_types = included_project_types
      @excluded_project_types = excluded_project_types
      @include_self_reported_and_ph = include_self_reported_and_ph
      @report = report
      @filter = ::Filters::HudFilterBase.new(user_id: report.user.id).update(report.options) # loading a user does a DB lookup, so avoid it
    end

    def calculate_batch(client_ids)
      # Original preload which loads ALL services
      # enrollments_for_clients = @enrollments.where(client_id: client_ids).preload(:client, enrollment: :services).group_by(&:client_id)

      # Same as the preload using includes/references so we can limit the scope of services included
      # s_t = GrdaWarehouse::Hud::Service.arel_table
      # enrollments_for_clients = @enrollments.where(client_id: client_ids).preload(:client).
      #   includes(enrollment: :services).
      #   references(enrollment: :services).
      #   where(s_t[:DateProvided].eq(nil).or(s_t[:DateProvided].between(@filter.start .. @filter.end))).
      #   group_by(&:client_id)

      # # One possible solution (poisoning the preload scope)
      # spm_enrollments = @enrollments.where(client_id: client_ids).preload(:client, enrollment: [:project, :client])
      # source_enrollments = spm_enrollments.map(&:enrollment)
      # scope = GrdaWarehouse::Hud::Service.bed_night.between(start_date: @filter.start, end_date: @filter.end)
      # # Inject the services scope into the preload
      # ::ActiveRecord::Associations::Preloader.new.preload(source_enrollments, :services, scope)
      # source_enrollments.each { |record| record.public_send(:services) }
      # enrollments_for_clients = spm_enrollments.group_by(&:client_id)

      # Services are really expensive to preload, for unknown reasons, however, the overall set of information we need is fairly small
      enrollments_for_clients = @enrollments.where(client_id: client_ids).preload(:client, :enrollment).group_by(&:client_id)
      batch_personal_ids = enrollments_for_clients.values.flatten.map(&:personal_id).uniq
      # Load all bed nights for these clients regardless of enrollment; we'll look them up as necessary
      # Bednights are indexed on `[EnrollmentID, PersonalID, data_source_id]`
      batch_services = GrdaWarehouse::Hud::Service.bed_night.
        between(start_date: @filter.start, end_date: @filter.end).
        where(PersonalID: batch_personal_ids). # impose some basic limit so we don't load the entire set of services
        pluck(:EnrollmentID, :PersonalID, :data_source_id, :DateProvided).
        group_by { |r| r.shift(3) }.
        transform_values(&:flatten)

      episodes = []
      bed_nights_per_episode = []
      enrollment_links_per_episode = []
      client_ids.each do |client_id|
        client = enrollments_for_clients[client_id]&.first&.client
        next unless client.present?

        episode_calculations = HudSpmReport::Fy2023::Episode.new(client: client, report: @report, filter: @filter, services: batch_services).
          compute_episode(
            enrollments_for_clients[client_id],
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
    # NOTE: `_bed_nights` are not currently in use in the UI, but might want to be enabled sometime in the future
    # to expose supporting data
    private def save_episodes!(episodes, _bed_nights, enrollment_links)
      # Import the episodes
      results = Episode.import!(episodes)
      # Attach the associations to their episode
      results.ids.each_with_index do |id, index|
        # Disabled to avoid database growth in production (see BedNight.import! below)
        # bn_for_episode = bed_nights[index]
        # bed_nights[index] = bn_for_episode.map do |bn|
        #   bn.episode_id = id
        #   bn
        # end
        el_for_episode = enrollment_links[index]
        enrollment_links[index] = el_for_episode.map do |el|
          el.episode_id = id
          el
        end
      end
      # Import the associations
      # BedNight.import!(bed_nights.flatten) # Disabled to avoid database growth in production
      EnrollmentLink.import!(enrollment_links.flatten)
    end
  end
end
