###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Inserts one HUD bed-night service (4.14, RecordType 200) for each night of every
# enrollment at the given projects. Nights run from EntryDate up to, but not
# including, ExitDate; open enrollments use `today` as the stand-in exit. Nights that
# already have a bed-night service are skipped, so re-running is a no-op.
#
# Works on the warehouse models so it applies to imported data sources, where
# enrollments relate to projects by ProjectID + data_source_id rather than project_pk.
# Intended as the final step when an imported data source is combined into single
# stays and the HMIS becomes the source of record; a later CSV import of the same
# data source would soft-delete the backfilled rows.
#
# Usage from a console:
#   HmisUtil::BedNightBackfill.new(project_pks: [12, 34], dry_run: true).run!
module HmisUtil
  class BedNightBackfill
    include ArelHelper

    BED_NIGHT = 200
    INSERT_BATCH_SIZE = 10_000
    # PersonalIDs fetched per query; keeps each enrollment/exit/service fetch bounded.
    CLIENT_FETCH_SIZE = 500

    ProjectSummary = Data.define(:project_pk, :project_name, :enrollment_count, :candidate_nights, :existing_nights, :inserted)
    Summary = Data.define(:projects, :inserted, :dry_run)

    EnrollmentRow = Data.define(:pk, :enrollment_id, :personal_id, :user_id, :entry_date, :exit_date)

    def initialize(project_pks:, dry_run: true, batch_size: INSERT_BATCH_SIZE, today: Date.current)
      @project_pks = Array(project_pks).map(&:to_i).uniq
      @dry_run = dry_run
      @batch_size = batch_size
      @today = today
      @touched_enrollment_pks = []
    end

    def run!
      projects = GrdaWarehouse::Hud::Project.find(@project_pks)
      summaries = projects.map { |project| process_project(project) }
      finalize! unless @dry_run
      summary = Summary.new(projects: summaries, inserted: summaries.sum(&:inserted), dry_run: @dry_run)
      puts "#{prefix}Total: #{summary.inserted} bed nights across #{summaries.size} projects"
      summary
    end

    private

    def enrollment_scope(project)
      project.enrollments.left_outer_joins(:exit)
    end

    def process_project(project)
      counts = scope_counts(project)
      report_scope(project, counts)
      inserted = 0
      pending_rows = []

      personal_ids = enrollment_scope(project).distinct.order(:PersonalID).pluck(:PersonalID)
      personal_ids.each_slice(CLIENT_FETCH_SIZE) do |ids|
        enrollments = fetch_enrollments(project, ids)
        existing = existing_bed_nights(project, enrollments)

        enrollments.group_by(&:personal_id).each_value do |client_enrollments|
          client_rows = client_enrollments.flat_map { |row| rows_for(row, existing, project.data_source_id) }
          next if client_rows.empty?

          pending_rows.concat(client_rows)
          @touched_enrollment_pks.concat(client_enrollments.map(&:pk))
          next if pending_rows.size < @batch_size

          inserted += flush!(pending_rows)
          pending_rows = []
        end
      end
      inserted += flush!(pending_rows)

      ProjectSummary.new(
        project_pk: project.id,
        project_name: project.ProjectName,
        enrollment_count: counts[:enrollment_count],
        candidate_nights: counts[:candidate_nights],
        existing_nights: counts[:existing_nights],
        inserted: inserted,
      ).tap { |summary| report_result(summary) }
    end

    # Candidate nights = SUM(GREATEST(COALESCE(ExitDate, today) - EntryDate, 0)) in one query.
    def scope_counts(project)
      nights = nf('GREATEST', [Arel::Nodes::Subtraction.new(stand_in_exit, e_t[:EntryDate]), 0])
      enrollment_count, candidate_nights = enrollment_scope(project).pick(Arel.star.count, nights.sum)
      existing_nights = GrdaWarehouse::Hud::Service.bed_night.
        where(data_source_id: project.data_source_id, EnrollmentID: enrollment_scope(project).select(:EnrollmentID)).
        count
      { enrollment_count: enrollment_count, candidate_nights: candidate_nights.to_i, existing_nights: existing_nights }
    end

    # ExitDate with `today` standing in for open enrollments.
    def stand_in_exit
      cl(ex_t[:ExitDate], @today)
    end

    def prefix
      @dry_run ? '[DRY RUN] ' : ''
    end

    def report_scope(project, counts)
      puts "#{prefix}Project #{project.id} #{project.ProjectName}: #{counts[:enrollment_count]} enrollments, " \
           "#{counts[:candidate_nights]} candidate nights, #{counts[:existing_nights]} existing bed nights"
    end

    def report_result(summary)
      verb = @dry_run ? 'would insert' : 'inserted'
      puts "#{prefix}Project #{summary.project_pk}: #{verb} #{summary.inserted} bed nights"
    end

    def fetch_enrollments(project, personal_ids)
      enrollment_scope(project).
        where(PersonalID: personal_ids).
        pluck(:id, :EnrollmentID, :PersonalID, :UserID, :EntryDate, stand_in_exit).
        map { |values| EnrollmentRow.new(*values) }
    end

    # { EnrollmentID => Set[Date] } of bed nights already present for these enrollments
    def existing_bed_nights(project, enrollments)
      GrdaWarehouse::Hud::Service.bed_night.
        where(data_source_id: project.data_source_id, EnrollmentID: enrollments.map(&:enrollment_id)).
        pluck(:EnrollmentID, :DateProvided).
        each_with_object(Hash.new { |h, k| h[k] = Set.new }) { |(enrollment_id, date), acc| acc[enrollment_id] << date }
    end

    def rows_for(enrollment, existing, data_source_id)
      last_night = enrollment.exit_date - 1.day
      return [] if last_night < enrollment.entry_date

      taken = existing[enrollment.enrollment_id]
      now = Time.current
      (enrollment.entry_date..last_night).filter_map do |date|
        next if taken.include?(date)

        {
          ServicesID: SecureRandom.uuid.delete('-'),
          EnrollmentID: enrollment.enrollment_id,
          PersonalID: enrollment.personal_id,
          data_source_id: data_source_id,
          DateProvided: date,
          RecordType: BED_NIGHT,
          TypeProvided: BED_NIGHT,
          UserID: enrollment.user_id,
          DateCreated: now,
          DateUpdated: now,
        }
      end
    end

    # One transaction per call; callers only flush at client boundaries.
    def flush!(rows)
      return 0 if rows.empty?
      return rows.size if @dry_run

      GrdaWarehouse::Hud::Service.transaction do
        rows.each_slice(@batch_size) { |slice| GrdaWarehouse::Hud::Service.insert_all(slice, returning: false) }
      end
      rows.size
    end

    def finalize!
      return if @touched_enrollment_pks.empty?

      GrdaWarehouse::Hud::Enrollment.where(id: @touched_enrollment_pks.uniq).in_batches.update_all(processed_as: nil, processed_hash: nil)
      # Shared queuer; it dedupes against an already-queued service history job.
      Hmis::Hud::Service.queue_service_history_processing!
    end
  end
end
