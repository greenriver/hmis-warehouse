###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Creates HMIS client files for objects that a migration already placed in S3. Each source row becomes
# an Active Storage blob and attachment (primary database) plus a `files` row and its taggings
# (warehouse database), shaped like a file uploaded through the HMIS file screen. Rows with type
# GrdaWarehouse::ClientFile become client headshots instead.
#
# Rows without a checksum are not processed. Progress lives in a tracking table keyed by s3_key, so a
# run can stop and resume. Rows that fail a check get a short message in its `errors` column and are
# retried on the next run.
#
# The source must be a table, or a UNION ALL view whose backing tables each have a unique index on
# s3_key; batches page through it in s3_key order. Before a production run, confirm the batch query
# uses those indexes (an Index Scan or Merge Append per backing table, and no Sort over the whole view):
#   EXPLAIN SELECT src.* FROM hmis_migration.mar_file_attachments_to_load src
#     LEFT JOIN hmis_migration.migrated_file_attachment_load_statuses t ON t.s3_key = src.s3_key
#     WHERE src.s3_key > '' AND t.active_storage_completed_at IS NULL AND NULLIF(TRIM(src.checksum), '') IS NOT NULL
#     ORDER BY src.s3_key LIMIT 1000;
#
# Usage from a console (or see the driver:hmis:load_migrated_file_attachments rake task):
#   HmisUtil::MigratedFileAttachmentLoader.new(source_table: 'hmis_migration.mar_file_attachments_to_load', dry_run: true).run!
# `limit:` caps the source rows a run examines, errored rows included; a later run continues after them.
module HmisUtil
  class MigratedFileAttachmentLoader
    DEFAULT_SOURCE_TABLE = 'hmis_migration.mar_file_attachments_to_load'
    DEFAULT_TRACKING_TABLE = 'hmis_migration.migrated_file_attachment_load_statuses'
    BATCH_SIZE = 1_000
    MAX_ERROR_LENGTH = 1_000
    IDENTIFY_BYTES = 4.kilobytes
    # Active Storage compares a downloaded file to the blob checksum as a base64 MD5 digest
    # (ActiveStorage::Downloader); any other form makes Blob#open raise ActiveStorage::IntegrityError.
    CHECKSUM_FORMAT = /\A[A-Za-z0-9+\/]{22}==\z/
    LOCK_NAME = 'HmisUtil::MigratedFileAttachmentLoader'

    REGULAR_TYPE = 'Hmis::File'
    HEADSHOT_TYPE = 'GrdaWarehouse::ClientFile'
    HEADSHOT_TAG = GrdaWarehouse::ClientFile.headshot_tag_name
    MIGRATION_TAG = 'Migrated from WellSky'
    # WellSky entity_name => AvailableFileTag name. Other entities get only the migration tag.
    ENTITY_TAG_MAPPING = {
      'ROI' => 'ROI',
      'Goal' => 'Case Plan',
      'Case Plans' => 'Case Plan',
      'Action Step' => 'Case Plan',
    }.freeze
    REQUIRED_TAGS = ENTITY_TAG_MAPPING.values.uniq.freeze

    # Polymorphic columns hold the STI base class, as Active Storage and acts-as-taggable-on write them.
    POLYMORPHIC_TYPE = 'GrdaWarehouse::File'
    ATTACHMENT_NAME = 'client_file'
    TAGGING_CONTEXT = 'tags'

    class MissingAvailableFileTags < StandardError; end
    class DuplicateSourceKeys < StandardError; end
    class AlreadyRunning < StandardError; end

    ObjectStat = Data.define(:byte_size)
    Summary = Data.define(:loaded, :headshots, :already_loaded, :errored, :warned, :dry_run)

    Candidate = Struct.new(:row, :errors, :warnings, :user_id, :updated_by_id, :byte_size, :content_type, keyword_init: true) do
      def key = row['s3_key']
      def type = row['type']
      def headshot? = type == HEADSHOT_TYPE
      def valid? = errors.empty?

      def entity_tag
        ENTITY_TAG_MAPPING[row['entity_name'].to_s.strip] unless headshot?
      end
    end

    # Reads the object size with one HEAD request. A 403 is treated like a 404: without s3:ListBucket,
    # S3 answers 403 for a missing key.
    class S3ObjectStat
      def initialize(client: nil, bucket_name: nil)
        @client = client
        @bucket_name = bucket_name
      end

      def call(key)
        ObjectStat.new(byte_size: client.head_object(bucket: bucket_name, key: key).content_length)
      rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::Forbidden
        nil
      end

      private

      def client
        @client ||= ActiveStorage::Blob.service.bucket.client
      end

      def bucket_name
        @bucket_name ||= ActiveStorage::Blob.service.bucket.name
      end
    end

    def initialize(
      source_table: DEFAULT_SOURCE_TABLE,
      tracking_table: DEFAULT_TRACKING_TABLE,
      required_tags: REQUIRED_TAGS,
      migration_tag: MIGRATION_TAG,
      batch_size: BATCH_SIZE,
      limit: nil,
      dry_run: true,
      object_stat: S3ObjectStat.new
    )
      raise ArgumentError, 'limit must be a positive integer' unless limit.nil? || (limit.is_a?(Integer) && limit.positive?)

      @source_table = source_table
      @tracking_table = tracking_table
      @required_tags = required_tags
      @migration_tag = migration_tag
      @batch_size = batch_size
      @limit = limit
      @dry_run = dry_run
      @object_stat = object_stat
    end

    def run!
      @counts = { loaded: 0, headshots: 0, already_loaded: 0, warned: 0 }
      @errored = Hash.new(0)

      with_run_lock do
        create_tracking_table
        load_available_tags!
        check_duplicate_keys!

        cursor = ''
        remaining = @limit
        loop do
          break if remaining&.zero?

          rows = fetch_batch(cursor, [@batch_size, remaining].compact.min)
          break if rows.empty?

          remaining -= rows.size if remaining
          cursor = rows.last['s3_key']
          process_batch(rows)
          puts "#{prefix}Through #{cursor}: #{@counts.map { |k, v| "#{k} #{v}" }.join(', ')}, errored #{@errored.values.sum}"
        end
        reset_tag_counts unless @dry_run
      end

      summary = Summary.new(**@counts, errored: @errored.to_h, dry_run: @dry_run)
      puts "#{prefix}#{summary.inspect}"
      summary
    end

    private

    def connection
      GrdaWarehouseBase.connection
    end

    def source = connection.quote_table_name(@source_table)
    def tracking = connection.quote_table_name(@tracking_table)
    def q(value) = connection.quote(value)
    def prefix = @dry_run ? '[DRY RUN] ' : ''

    # A second run started while one is in its warehouse transaction would see the first run's
    # attachments without their files, treat them as orphans, and load the rows again.
    def with_run_lock
      lock_key = "hashtext(#{q(LOCK_NAME)})"
      raise AlreadyRunning, "Another #{self.class.name} run holds the lock" unless connection.select_value("SELECT pg_try_advisory_lock(#{lock_key})")

      begin
        yield
      ensure
        connection.select_value("SELECT pg_advisory_unlock(#{lock_key})")
      end
    end

    def create_tracking_table
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{tracking} (
          s3_key text NOT NULL PRIMARY KEY,
          active_storage_started_at timestamp,
          active_storage_completed_at timestamp,
          active_storage_blob_id bigint,
          errors varchar
        )
      SQL
    end

    def load_available_tags!
      names = @required_tags + [@migration_tag]
      @available_tags = GrdaWarehouse::AvailableFileTag.where(name: names).index_by(&:name)
      missing = names - @available_tags.keys
      raise MissingAvailableFileTags, "Missing available file tags: #{missing.join(', ')}" if missing.any?

      # Created here, outside the write transactions, so a rolled-back batch can't leave a cached id
      # for a tag row that was never committed.
      tag_names = @available_tags.values.map { |tag| tag.id.to_s } + [HEADSHOT_TAG]
      @tag_ids = tag_names.index_with { |name| ActsAsTaggableOn::Tag.find_or_create_by!(name: name).id }
    end

    def check_duplicate_keys!
      count = connection.select_value(<<~SQL).to_i
        SELECT count(*) FROM (SELECT s3_key FROM #{source} GROUP BY s3_key HAVING count(*) > 1) duplicates
      SQL
      raise DuplicateSourceKeys, "#{count} s3_keys appear more than once in #{@source_table}" if count.positive?
    end

    def fetch_batch(cursor, size)
      connection.select_all(<<~SQL).to_a
        SELECT src.* FROM #{source} src
        LEFT JOIN #{tracking} t ON t.s3_key = src.s3_key
        WHERE src.s3_key > #{q(cursor)} AND t.active_storage_completed_at IS NULL
          AND NULLIF(TRIM(src.checksum), '') IS NOT NULL
        ORDER BY src.s3_key
        LIMIT #{size.to_i}
      SQL
    end

    def process_batch(rows)
      candidates = validate(rows)
      if @dry_run
        candidates.each { |candidate| count(candidate) }
        return
      end

      started_at = Time.current
      upsert_tracking(candidates.select(&:valid?).map { |c| { s3_key: c.key, active_storage_started_at: started_at, errors: nil } })
      fill_object_stats(candidates.select(&:valid?))
      identify_content_types(candidates.select(&:valid?))
      errored = candidates.reject(&:valid?)
      upsert_tracking(errored.map { |c| { s3_key: c.key, errors: c.errors.join('; ') } })
      errored.each { |candidate| count(candidate) }

      valid = candidates.select(&:valid?)
      write(valid) if valid.any?
    end

    def validate(rows)
      candidates = rows.map do |row|
        Candidate.new(row: row, errors: [], warnings: [], byte_size: row['size'])
      end
      hmis_client_ids = Hmis::Hud::Client.where(data_source_id: hmis_data_source.id, id: candidates.map { |c| c.row['client_id'] }).pluck(:id).to_set
      enrollment_owners = Hmis::Hud::Enrollment.where(data_source_id: hmis_data_source.id, id: candidates.map { |c| c.row['enrollment_id'] }.compact).
        joins(:client).pluck(:id, Hmis::Hud::Client.arel_table[:id]).to_h
      user_ids = User.with_deleted.where(id: candidates.flat_map { |c| [c.row['user_id'], c.row['updated_by_id']] }.compact).pluck(:id).to_set

      candidates.each do |candidate|
        row = candidate.row
        candidate.errors << "unknown type #{candidate.type}" unless candidate.type.in?([REGULAR_TYPE, HEADSHOT_TYPE])
        candidate.errors << 'no name' if row['name'].blank?
        candidate.errors << 'checksum is not a base64 MD5' unless row['checksum'].to_s.match?(CHECKSUM_FORMAT)
        if !row['client_id'].in?(hmis_client_ids)
          candidate.errors << "client #{row['client_id']} not in HMIS data source"
        elsif !candidate.headshot?
          if row['enrollment_id'].nil?
            candidate.errors << 'no enrollment_id'
          elsif enrollment_owners[row['enrollment_id']] != row['client_id']
            candidate.errors << "enrollment #{row['enrollment_id']} not found for client #{row['client_id']}"
          end
        end

        missing_users = [row['user_id'], row['updated_by_id']].compact.uniq.reject { |id| id.in?(user_ids) }
        candidate.warnings.concat(missing_users.map { |id| "user #{id} not found, left blank" })
        candidate.user_id = row['user_id'] if row['user_id'].in?(user_ids)
        candidate.updated_by_id = row['updated_by_id'] if row['updated_by_id'].in?(user_ids)
      end
    end

    def fill_object_stats(candidates)
      candidates.reject(&:byte_size).each do |candidate|
        stat = @object_stat.call(candidate.key)
        if stat
          candidate.byte_size = stat.byte_size
        else
          candidate.errors << 'S3 object not found'
        end
      end
    end

    # The source content_type wins, then the file name's extension, then the file's first bytes (the
    # same 4 KB Active Storage reads to identify an upload).
    def identify_content_types(candidates)
      candidates.each do |candidate|
        name = candidate.row['name'].to_s
        candidate.content_type = candidate.row['content_type'].to_s.strip.presence ||
          (Marcel::MimeType.for(name: name) if File.extname(name).delete_prefix('.').present?) ||
          content_type_from_storage(candidate)
      end
    end

    def content_type_from_storage(candidate)
      Marcel::MimeType.for(ActiveStorage::Blob.service.download_chunk(candidate.key, 0...IDENTIFY_BYTES))
    rescue ActiveStorage::FileNotFoundError, Aws::S3::Errors::Forbidden
      candidate.errors << 'S3 object not found'
      nil
    end

    def count(candidate)
      if !candidate.valid?
        @errored[candidate.errors.join('; ').gsub(/ \d+/, '')] += 1
        return
      end

      @counts[:warned] += 1 if candidate.warnings.any?
      @counts[candidate.headshot? ? :headshots : :loaded] += 1
    end

    # Primary commits before warehouse. If the warehouse commit then fails, the attachments left behind
    # point at file ids that were never committed; the next run deletes them and loads the row again.
    def write(candidates)
      GrdaWarehouseBase.transaction do
        file_ids = ActiveStorage::Record.transaction { write_blobs_files_and_attachments(candidates) }
        insert_taggings(candidates, file_ids)
        completed_at = Time.current
        upsert_tracking(
          candidates.map do |candidate|
            {
              s3_key: candidate.key,
              active_storage_completed_at: completed_at,
              active_storage_blob_id: @blob_ids.fetch(candidate.key),
              errors: candidate.warnings.join('; ').presence,
            }
          end,
        )
      end
    end

    # Returns { s3_key => file id } for the files created in this call.
    def write_blobs_files_and_attachments(candidates)
      now = Time.current
      ActiveStorage::Blob.insert_all(
        candidates.map do |candidate|
          {
            key: candidate.key,
            filename: candidate.row['name'],
            content_type: candidate.content_type,
            metadata: { identified: true }.to_json,
            service_name: ActiveStorage::Blob.service.name.to_s,
            byte_size: candidate.byte_size,
            checksum: candidate.row['checksum'],
            created_at: candidate.row['created_at'] || now,
          }
        end,
        unique_by: :key,
      )
      @blob_ids = ActiveStorage::Blob.where(key: candidates.map(&:key)).pluck(:key, :id).to_h

      existing = ActiveStorage::Attachment.where(blob_id: @blob_ids.values, record_type: POLYMORPHIC_TYPE, name: ATTACHMENT_NAME).
        pluck(:id, :blob_id, :record_id)
      committed_file_ids = GrdaWarehouse::File.with_deleted.where(id: existing.map(&:last)).pluck(:id).to_set
      orphans, loaded = existing.partition { |(_, _, record_id)| !record_id.in?(committed_file_ids) }
      ActiveStorage::Attachment.where(id: orphans.map(&:first)).delete_all if orphans.any?
      loaded_blob_ids = loaded.map(&:second).to_set

      already, pending = candidates.partition { |candidate| @blob_ids.fetch(candidate.key).in?(loaded_blob_ids) }
      @counts[:already_loaded] += already.size
      return {} if pending.empty?

      # Ids are allocated up front so each file can be matched to its attachment and taggings;
      # insert_all ... RETURNING does not promise row order.
      file_ids = pending.map(&:key).zip(allocate_file_ids(pending.size)).to_h
      GrdaWarehouse::File.insert_all!(pending.map { |candidate| file_attributes(candidate, file_ids.fetch(candidate.key), now) })
      ActiveStorage::Attachment.insert_all!(
        pending.map do |candidate|
          {
            name: ATTACHMENT_NAME,
            record_type: POLYMORPHIC_TYPE,
            record_id: file_ids.fetch(candidate.key),
            blob_id: @blob_ids.fetch(candidate.key),
            created_at: candidate.row['created_at'] || now,
          }
        end,
      )
      pending.each { |candidate| count(candidate) }
      file_ids
    end

    def allocate_file_ids(count)
      sequence = connection.select_value("SELECT pg_get_serial_sequence('files', 'id')")
      connection.select_values("SELECT nextval(#{q(sequence)}) FROM generate_series(1, #{count.to_i})")
    end

    def file_attributes(candidate, id, now)
      row = candidate.row
      {
        id: id,
        type: candidate.type,
        client_id: row['client_id'],
        enrollment_id: candidate.headshot? ? nil : row['enrollment_id'],
        user_id: candidate.user_id,
        updated_by_id: candidate.updated_by_id,
        name: candidate.headshot? ? HEADSHOT_TAG : row['name'],
        note: row['note'],
        visible_in_window: candidate.headshot? ? false : nil,
        confidential: false,
        created_at: row['created_at'] || now,
        updated_at: row['updated_at'] || now,
      }
    end

    # HMIS reads file tags as AvailableFileTag ids (ClientFileBase#tags), so each tag is stored under the
    # id's string. The headshot tag is the exception: the client_photos scope matches it by name.
    def insert_taggings(candidates, file_ids)
      now = Time.current
      rows = candidates.select { |candidate| file_ids.key?(candidate.key) }.flat_map do |candidate|
        names = [available_tag_name(@migration_tag)]
        names << (candidate.headshot? ? HEADSHOT_TAG : candidate.entity_tag&.then { |name| available_tag_name(name) })
        names.compact.map do |name|
          {
            tag_id: tag_id(name),
            taggable_id: file_ids.fetch(candidate.key),
            taggable_type: POLYMORPHIC_TYPE,
            context: TAGGING_CONTEXT,
            created_at: now,
          }
        end
      end
      ActsAsTaggableOn::Tagging.insert_all!(rows) if rows.any?
    end

    def available_tag_name(name)
      @available_tags.fetch(name).id.to_s
    end

    def tag_id(name)
      @tag_ids.fetch(name)
    end

    def reset_tag_counts
      tags = ActsAsTaggableOn::Tag.arel_table
      taggings = ActsAsTaggableOn::Tagging.arel_table
      ActsAsTaggableOn::Tag.where(id: @tag_ids.values).update_all(
        taggings_count: Arel::Nodes::Grouping.new(
          taggings.project(Arel.star.count).where(taggings[:tag_id].eq(tags[:id])),
        ),
      )
    end

    # rows: hashes with the same keys, always including :s3_key.
    def upsert_tracking(rows)
      return if rows.empty?

      columns = rows.first.keys
      tuples = rows.map do |row|
        values = columns.map { |column| column == :errors ? row[column]&.truncate(MAX_ERROR_LENGTH) : row[column] }
        "(#{values.map { |value| q(value) }.join(', ')})"
      end
      updates = (columns - [:s3_key]).map { |column| "#{column} = EXCLUDED.#{column}" }
      connection.execute(<<~SQL)
        INSERT INTO #{tracking} (#{columns.join(', ')}) VALUES #{tuples.join(', ')}
        ON CONFLICT (s3_key) DO UPDATE SET #{updates.join(', ')}
      SQL
    end

    def hmis_data_source
      @hmis_data_source ||= GrdaWarehouse::DataSource.hmis.first!
    end
  end
end
