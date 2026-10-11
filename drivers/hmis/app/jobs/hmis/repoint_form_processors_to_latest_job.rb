###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# == Hmis::RepointFormProcessorsToLatestJob
#
# Repoints form processors (`hmis_form_processors.definition_id`) from retired form definitions to the latest published
# version of the same form identifier, for custom assessments, case notes, services and current living situations.
#
# WHY / WHEN
# A record keeps the definition it was collected with, and is shown with it even after that form is retired. Assessments
# only upgrade when edited (on unlock); case notes, services and CLS are pinned and are never upgraded. Retiring a form
# and publishing a new version therefore does not change existing records. Run this when records should follow the new
# version, for example when a form bug is found after an import, the form is fixed and republished, and the imported
# records need to use it. @see docs/features/hmis/hmis-form-resolution.md ("Choosing a definition for an existing record")
#
# NOTES
# - For case notes, services and CLS the new version also becomes the form used to Edit them.
# - Questions that exist only in the retired version stop showing (the stored values are kept). Compare versions first.
# - Skips work-in-progress assessments, HUD assessment roles and system forms.
# - Retired definitions with no published version are skipped (reported in the log).
# - Uses `update_all`: no callbacks and no PaperTrail versions. Safe to stop and re-run; an advisory lock prevents overlap.
# - `definition_id` has no index, so the job scans the processors table once, in batches with a transaction each.
#
# USAGE
#   Hmis::RepointFormProcessorsToLatestJob.perform_now                                  # dry run, sole HMIS data source, all supported roles and forms
#   Hmis::RepointFormProcessorsToLatestJob.perform_later(dry_run: false)                # apply, queued
#   Hmis::RepointFormProcessorsToLatestJob.perform_later(roles: ['SERVICE'], identifiers: ['my_form'], dry_run: false)
#
# Arguments:
# - data_source_id (default: the sole HMIS data source)
# - roles (default: all of SUPPORTED_ROLES)
# - identifiers (default: every form with a retired version)
# - dry_run (default: true; writes nothing)
#
# Returns one entry per retired definition: { role:, identifier:, from_version:, to_version:, processors: }
module Hmis
  class RepointFormProcessorsToLatestJob < BaseJob
    include NotifierConfig

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    SUPPORTED_ROLES = ['CUSTOM_ASSESSMENT', 'CASE_NOTE', 'SERVICE', 'CURRENT_LIVING_SITUATION'].freeze
    ASSESSMENT_OWNER_TYPE = 'Hmis::Hud::CustomAssessment'
    BATCH_SIZE = 10_000

    def perform(data_source_id: nil, roles: nil, identifiers: nil, dry_run: true)
      setup_notifier('Repoint HMIS form processors')

      @data_source_id = data_source_id || sole_hmis_data_source_id
      @roles = Array(roles || SUPPORTED_ROLES).map(&:to_s)
      @identifiers = identifiers&.map(&:to_s)
      @dry_run = dry_run

      unsupported = @roles - SUPPORTED_ROLES
      raise ArgumentError, "unsupported roles: #{unsupported.join(', ')} (supported: #{SUPPORTED_ROLES.join(', ')})" if unsupported.any?

      # returns the block's result, or false when another run holds the lock
      results = ::GrdaWarehouseBase.with_advisory_lock('hmis_repoint_form_processors_to_latest', timeout_seconds: 0) { repoint_all }
      return results if results

      log 'another run holds the lock, nothing done'
      []
    end

    private

    def repoint_all
      log "#{@dry_run ? 'DRY RUN: ' : ''}repointing #{@roles.join(', ')} form processors in data source #{@data_source_id} to the latest published form"

      without_published = retired_definitions.map(&:identifier).uniq - published_by_identifier.keys
      log "no published version, skipped: #{without_published.sort.join(', ')}" if without_published.any?
      if stale_definitions.empty?
        log 'nothing to repoint'
        return []
      end
      log "leaving #{wip_assessment_ids.size} work-in-progress assessments alone" if wip_assessment_ids.any?

      counts = @dry_run ? count_stale : repoint!

      results = stale_definitions.sort_by { |definition| [definition.role, definition.identifier, definition.version] }.map do |definition|
        {
          role: definition.role,
          identifier: definition.identifier,
          from_version: definition.version,
          to_version: published_by_identifier.fetch(definition.identifier).version,
          processors: counts.fetch(definition.id, 0),
        }
      end
      report(results)
      results
    end

    # Dry run: processors still on each stale definition, minus work-in-progress assessments (two grouped counts)
    def count_stale
      total = Hmis::Form::FormProcessor.where(definition_id: published_id_by_stale_id.keys).group(:definition_id).count
      wip_assessment_ids.to_a.each_slice(5_000) do |slice|
        Hmis::Form::FormProcessor.where(owner_type: ASSESSMENT_OWNER_TYPE, owner_id: slice, definition_id: published_id_by_stale_id.keys).
          group(:definition_id).count.each { |definition_id, count| total[definition_id] -= count }
      end
      total
    end

    # One pass over the stale processors in primary key order; one transaction per batch.
    # Returns { stale definition id => number of processors updated }.
    def repoint!
      updated = Hash.new(0)
      Hmis::Form::FormProcessor.where(definition_id: published_id_by_stale_id.keys).in_batches(of: BATCH_SIZE) do |batch|
        # each row is [processor id, owner type, owner id, definition id]
        rows = batch.pluck(:id, :owner_type, :owner_id, :definition_id)
        rows.reject! { |_, owner_type, owner_id, _| owner_type == ASSESSMENT_OWNER_TYPE && wip_assessment_ids.include?(owner_id) }

        Hmis::Form::FormProcessor.transaction do
          # one update per stale definition: all of its processors in this batch move to its published version
          rows.group_by(&:last).each do |definition_id, definition_rows|
            published_id = published_id_by_stale_id.fetch(definition_id)
            # only rows that still point at the stale definition, so a concurrent form submission is not overwritten
            updated[definition_id] += Hmis::Form::FormProcessor.
              where(id: definition_rows.map(&:first), definition_id: definition_id).
              update_all(definition_id: published_id)
          end
        end
        log "updated #{updated.values.sum} processors so far"
      end
      updated
    end

    def report(results)
      lines = results.map do |r|
        "#{r[:role]} #{r[:identifier]} v#{r[:from_version]} (retired) -> v#{r[:to_version]} (published): #{r[:processors]} processors"
      end
      summary = "#{@dry_run ? 'DRY RUN: ' : ''}#{results.sum { |r| r[:processors] }} processors#{@dry_run ? ' would be' : ''} repointed in data source #{@data_source_id}\n#{lines.join("\n")}"
      log summary
      send_single_notification(summary, 'Repoint HMIS form processors') unless @dry_run
    end

    # Retired definitions that have a published version of the same identifier: the ones to repoint away from.
    def stale_definitions
      @stale_definitions ||= retired_definitions.select { |definition| published_by_identifier.key?(definition.identifier) }
    end

    # { stale definition id => id of the published definition of the same form }: where its processors are repointed to.
    def published_id_by_stale_id
      @published_id_by_stale_id ||= stale_definitions.to_h { |definition| [definition.id, published_by_identifier.fetch(definition.identifier).id] }
    end

    def retired_definitions
      @retired_definitions ||= definitions.retired.to_a
    end

    # { identifier => published definition }. At most one version of an identifier is published per data source
    # (unique index uidx_hmis_form_definitions_one_published_per_identifier), so no version ordering is needed.
    def published_by_identifier
      @published_by_identifier ||= definitions.published.index_by(&:identifier)
    end

    # Set of work-in-progress assessment ids. Only assessments can be saved in progress, and their processors are skipped.
    def wip_assessment_ids
      @wip_assessment_ids ||= if @roles.include?('CUSTOM_ASSESSMENT')
        Hmis::Hud::CustomAssessment.where(data_source_id: @data_source_id, wip: true).pluck(:id).to_set
      else
        Set.new
      end
    end

    # Definitions in scope, without loading the large `definition` JSON column
    def definitions
      scope = Hmis::Form::Definition.in_data_source(@data_source_id).with_role(@roles).exclude_definition_from_select
      scope = scope.where(identifier: @identifiers) if @identifiers
      scope
    end

    def sole_hmis_data_source_id
      ::GrdaWarehouse::DataSource.hmis.sole.id
    rescue ActiveRecord::RecordNotFound, ActiveRecord::SoleRecordExceeded
      raise ArgumentError, 'expected exactly one HMIS data source; pass data_source_id:'
    end

    def log(message)
      Rails.logger.info("[RepointFormProcessorsToLatest] #{message}")
    end
  end
end
