# Reduces bloat in tables and indexes
#
# Test nd
# with this:
# DBA_MIN_ROWS=200  DBA_MIN_UNUSED_INDEX_SIZE=10000 DBA_BLOAT_CUTOFF=1 DBA_SIZE_CUTOFF=100000 ./bin/rake dba:dry_run
class DBA::DatabaseBloat
  attr_accessor :ar_base_class
  attr_accessor :dry_run

  # percentage wasted
  BLOAT_CUTOFF = ENV.fetch('DBA_BLOAT_CUTOFF', 30).to_i

  # wasted space in bytes
  SIZE_CUTOFF  = ENV.fetch('DBA_SIZE_CUTOFF', 100_000_000).to_i

  # Go easy on the database's other users and don't do all of them
  MAX_PER_RUN  = ENV.fetch('DBA_MAX_PER_RUN', 10).to_i

  # Ignore indexes under this size in bytes (unused index checking)
  MIN_UNUSED_INDEX_SIZE = ENV.fetch('DBA_MIN_UNUSED_INDEX_SIZE', 500_000_000).to_i

  # minimum number of rows or dead tuples in a table to consider it worthy of vacuuming
  MIN_ROWS = ENV.fetch('DBA_MIN_ROWS', 1_000).to_i

  # minimum percentage of non-analyzed rows to trigger adjusting autovaccuum
  MIN_PCT_NOT_ANALZYED = ENV.fetch('DBA_MIN_PCT_NOT_ANALYZED', 4).to_i

  SERVER_PG_REPACK_VERSION = '1.4.7'.freeze

  def initialize(ar_base_class:, dry_run: false)
    self.ar_base_class = ar_base_class
    self.dry_run = dry_run
  end

  def self.all_databases!(meth, dry_run: false)
    [ApplicationRecord, GrdaWarehouseBase, HealthBase, ReportingBase, CasBase].each do |ar_base_class|
      Rails.logger.tagged({ 'dba' => true, 'base_class' => ar_base_class.to_s, 'method' => meth.to_s }) do
        db = DBA::DatabaseBloat.new(ar_base_class: ar_base_class, dry_run: dry_run)
        db.send(meth)
      end
    end
  end

  def show_cache_hits!
    cache_hit_rates.each do |row|
      if row['ratio'].to_f < 0.7
        Rails.logger.warn "Cache #{row['name']} is too low in #{row['current_database']}: #{row['ratio'].round(2)}"
      elsif row['ratio'].to_f < 0.85
        Rails.logger.info "Cache #{row['name']} is a little low in #{row['current_database']}: #{row['ratio'].round(2)}"
      end
    end
  end

  def index_drops!
    unused_indexes.each do |row|
      Rails.logger.info("EVIDENCE: #{row}")
      run("DROP INDEX \"#{row['index']}\";")
    end
  end

  # Runs in the background and doesn't get an aggresive lock on anything.
  # Should be safe unless we're low on I/O burst credits
  def reindex!
    catch(:enough) do
      bloated_indexes.each.with_index do |row, i|
        sql = %<REINDEX INDEX CONCURRENTLY "#{row['schemaname']}"."#{row['idxname']}";>
        Rails.logger.info("EVIDENCE: #{row}")
        run(sql)
        throw :enough if i + 1 == MAX_PER_RUN && !dry_run
      end
    end
  end

  # This aquires an aggresive (exclusive) lock.
  def vacuum_full!
    catch(:enough) do
      bloated_tables.each.with_index do |row, i|
        sql = %<VACUUM FULL "#{row['schemaname']}"."#{row['tblname']}";>
        Rails.logger.info("EVIDENCE: #{row}")

        run(sql)

        adjust_autovacuum_for(row)

        throw :enough if i + 1 == MAX_PER_RUN && !dry_run
      end
    end
  end

  # Autovacuum is tied to autoanalyze
  def adjust_autovacuum_for(row)
    return unless row['percent_unanalyzed'] > MIN_PCT_NOT_ANALZYED

    autovacuum_analyze_threshold = (row['autovacuum_analyze_threshold'] / 2).to_i
    autovacuum_analyze_scale_factor = (row['autovacuum_analyze_scale_factor'] / 2).round(2)

    autovacuum_vacuum_threshold = (row['autovacuum_vacuum_threshold'] / 2).to_i
    autovacuum_vacuum_scale_factor = (row['autovacuum_vacuum_scale_factor'] / 2).round(2)

    Rails.logger.warn 'Not ready to automatically recommend autovacuum settings.'

    sql = format(%<ALTER TABLE "%s"."%s" SET (autovacuum_analyze_threshold = %d, autovacuum_analyze_scale_factor = %f, autovacuum_vacuum_threshold = %d, autovacuum_vacuum_scale_factor = %f);>,
                 row['schemaname'],
                 row['tblname'],
                 autovacuum_analyze_threshold,
                 autovacuum_analyze_scale_factor,
                 autovacuum_vacuum_threshold,
                 autovacuum_vacuum_scale_factor
                )
    Rails.logger.info sql
    run(sql)
  end

  # This is like a vacuum full, but orchastrated by pg_repack which doesn't
  # aquire exlusive locks on the table
  def repack!
    catch(:enough) do
      port = ar_base_class.connection_db_config.configuration_hash[:port].presence || "5432"
      host = File.exist?(ar_base_class.connection_db_config.configuration_hash[:host].to_s) ? CGI.escape(ar_base_class.connection_db_config.configuration_hash[:host]) : ar_base_class.connection_db_config.configuration_hash[:host]
      username = ar_base_class.connection_db_config.configuration_hash[:username]
      database = ar_base_class.connection_db_config.configuration_hash[:database]
      # password should be in your .pgpass file

      bloated_tables.each.with_index do |row, i|
        # puts row

        # need pg_repack to match match database extension. That's why we have
        # the containerized pg_repack image in our deployed environments
        options = "--no-superuser-check -U #{username} -d #{database} -h #{host} -p #{port} -t #{row['schemaname']}.#{row['tblname']}"

        cmd = "pg_repack #{options}"

        raise "version of pg_repack needs to match that in the database"

        Rails.logger.info("Repacking #{row['tblname']}")
        system(cmd)

        if $?.exitstatus != 0
          raise "running repack failed."
        end

        adjust_autovacuum_for(row)

        throw :enough if i + 1 == MAX_PER_RUN && !dry_run
      end
    end
  end

  private

  # for finding bloat, etc. Harmless things only
  def always_run(sql)
    results = nil
    r = Benchmark.measure do
      results = ar_base_class.connection.exec_query(sql)
    end
    results
  end

  # for the dangerous queries
  def run(sql)
    Rails.logger.info "#{sql}"

    if !dry_run
      results = nil
      r = Benchmark.measure do
        results = ar_base_class.connection.exec_query(sql)
      end
      Rails.logger.info "Ran in #{r.real} seconds"
      results
    end
  end

  def bloated_tables
    always_run(bloated_tables_sql)
  end

  def bloated_tables_sql
    <<~SQL
      /*
        current_database: name of the current database.
        schemaname: schema of the table.
        tblname: the table name.
        real_size: real size of the table.
        extra_size: estimated extra size not used/needed in the table. This extra size is composed by the fillfactor, bloat and alignment padding spaces.
        extra_pct: estimated percentage of the real size used by extra_size.
        fillfactor: the fillfactor of the table.
        bloat_size: estimated size of the bloat without the extra space kept for the fillfactor.
        bloat_pct: estimated percentage of the real size used by bloat_size.
        is_na: is the estimation "Not Applicable" ? If true, do not trust the stats.

        WARNING: executed with a non-superuser role, the query inspect only tables
        and materialized view (9.3+) you are granted to read. This query is
        compatible with PostgreSQL 9.0 and greater

        https://github.com/ioguix/pgsql-bloat-estimation

      */
      WITH results AS (
        SELECT current_database(), schemaname, tblname, bs*tblpages AS real_size,
          (tblpages-est_tblpages)*bs AS extra_size,
          CASE WHEN tblpages > 0 AND tblpages - est_tblpages > 0
            THEN 100 * (tblpages - est_tblpages)/tblpages::float
            ELSE 0
          END AS extra_pct, fillfactor,
          CASE WHEN tblpages - est_tblpages_ff > 0
            THEN (tblpages-est_tblpages_ff)*bs
            ELSE 0
          END AS bloat_size,
          CASE WHEN tblpages > 0 AND tblpages - est_tblpages_ff > 0
            THEN 100 * (tblpages - est_tblpages_ff)/tblpages::float
            ELSE 0
          END AS bloat_pct, is_na
          -- , tpl_hdr_size, tpl_data_size, (pst).free_percent + (pst).dead_tuple_percent AS real_frag -- (DEBUG INFO)
        FROM (
          SELECT ceil( reltuples / ( (bs-page_hdr)/tpl_size ) ) + ceil( toasttuples / 4 ) AS est_tblpages,
            ceil( reltuples / ( (bs-page_hdr)*fillfactor/(tpl_size*100) ) ) + ceil( toasttuples / 4 ) AS est_tblpages_ff,
            tblpages, fillfactor, bs, tblid, schemaname, tblname, heappages, toastpages, is_na
            -- , tpl_hdr_size, tpl_data_size, pgstattuple(tblid) AS pst -- (DEBUG INFO)
          FROM (
            SELECT
              ( 4 + tpl_hdr_size + tpl_data_size + (2*ma)
                - CASE WHEN tpl_hdr_size%ma = 0 THEN ma ELSE tpl_hdr_size%ma END
                - CASE WHEN ceil(tpl_data_size)::int%ma = 0 THEN ma ELSE ceil(tpl_data_size)::int%ma END
              ) AS tpl_size, bs - page_hdr AS size_per_block, (heappages + toastpages) AS tblpages, heappages,
              toastpages, reltuples, toasttuples, bs, page_hdr, tblid, schemaname, tblname, fillfactor, is_na
              -- , tpl_hdr_size, tpl_data_size
            FROM (
              SELECT
                tbl.oid AS tblid, ns.nspname AS schemaname, tbl.relname AS tblname, tbl.reltuples,
                tbl.relpages AS heappages, coalesce(toast.relpages, 0) AS toastpages,
                coalesce(toast.reltuples, 0) AS toasttuples,
                coalesce(substring(
                  array_to_string(tbl.reloptions, ' ')
                  FROM 'fillfactor=([0-9]+)')::smallint, 100) AS fillfactor,
                current_setting('block_size')::numeric AS bs,
                CASE WHEN version()~'mingw32' OR version()~'64-bit|x86_64|ppc64|ia64|amd64' THEN 8 ELSE 4 END AS ma,
                24 AS page_hdr,
                23 + CASE WHEN MAX(coalesce(s.null_frac,0)) > 0 THEN ( 7 + count(s.attname) ) / 8 ELSE 0::int END
                   + CASE WHEN bool_or(att.attname = 'oid' and att.attnum < 0) THEN 4 ELSE 0 END AS tpl_hdr_size,
                sum( (1-coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 0) ) AS tpl_data_size,
                bool_or(att.atttypid = 'pg_catalog.name'::regtype)
                  OR sum(CASE WHEN att.attnum > 0 THEN 1 ELSE 0 END) <> count(s.attname) AS is_na
              FROM pg_attribute AS att
                JOIN pg_class AS tbl ON att.attrelid = tbl.oid
                JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
                LEFT JOIN pg_stats AS s ON s.schemaname=ns.nspname
                  AND s.tablename = tbl.relname AND s.inherited=false AND s.attname=att.attname
                LEFT JOIN pg_class AS toast ON tbl.reltoastrelid = toast.oid
              WHERE NOT att.attisdropped
                AND tbl.relkind in ('r','m')
              GROUP BY 1,2,3,4,5,6,7,8,9,10
              ORDER BY 2,3
            ) AS s
          ) AS s2
        ) AS s3
      ),#{vacuum_stats_common_table_sql_snippet}

      select
        r.schemaname,
        r.tblname,
        pg_size_pretty(r.real_size::bigint) as real_size,
        pg_size_pretty(r.extra_size::bigint) as extra_size,
        round(r.extra_pct) as extra_pct,
        round(r.bloat_pct) as bloat_pct,
        pg_size_pretty(r.bloat_size::bigint) as bloat_size_pretty,
        r.bloat_size,
        r.fillfactor,
        v.last_vacuum,
        v.last_autovacuum,
        v.rowcount,
        v.dead_rowcount,
        v.autovacuum_vacuum_threshold,
        v.autovacuum_vacuum_scale_factor, -- percentage of table length that triggers an autovacuum after exceeding the usually tiny offset that's typically 50
        v.autovacuum_threshold::bigint,
        v.autovacuum_analyze_scale_factor,
        v.autovacuum_analyze_threshold,
        v.expect_autovacuum,
        v.percent_unanalyzed
      FROM
        results r
        JOIN vacuum_results v ON (
          r.schemaname = v.schemaname AND
          r.tblname = v.tblname
        )
      WHERE
        NOT r.is_na
        AND r.schemaname not in ('information_schema', 'pg_catalog')
        AND r.bloat_size > #{SIZE_CUTOFF} -- raw size of wasted space
        -- fillfactor is purposeful bloat/wasted space so subtract it out. usually 100 on tables, though
        AND (r.bloat_pct - (100 - r.fillfactor)) >= #{BLOAT_CUTOFF} -- percentage of wasted space relative to how filled it should be
        AND v.rowcount > #{MIN_ROWS} -- approximate number of rows in the table
        AND v.dead_rowcount > #{MIN_ROWS} -- approximate number of dead rows that are un-vacuumed
      ORDER BY
        r.bloat_size desc
    SQL
  end

  def bloated_indexes
    always_run(bloated_indexes_sql)
  end

  def bloated_indexes_sql
    <<~SQL
    with results AS (
        SELECT current_database(), nspname AS schemaname, tblname, idxname, bs*(relpages)::bigint AS real_size,
          bs*(relpages-est_pages)::bigint AS extra_size,
          100 * (relpages-est_pages)::float / relpages AS extra_pct,
          fillfactor,
          CASE WHEN relpages > est_pages_ff
            THEN bs*(relpages-est_pages_ff)
            ELSE 0
          END AS bloat_size,
          100 * (relpages-est_pages_ff)::float / relpages AS bloat_pct,
          is_na
          -- , 100-(pst).avg_leaf_density AS pst_avg_bloat, est_pages, index_tuple_hdr_bm, maxalign, pagehdr, nulldatawidth, nulldatahdrwidth, reltuples, relpages -- (DEBUG INFO)
        FROM (
          SELECT coalesce(1 +
                 ceil(reltuples/floor((bs-pageopqdata-pagehdr)/(4+nulldatahdrwidth)::float)), 0 -- ItemIdData size + computed avg size of a tuple (nulldatahdrwidth)
              ) AS est_pages,
              coalesce(1 +
                 ceil(reltuples/floor((bs-pageopqdata-pagehdr)*fillfactor/(100*(4+nulldatahdrwidth)::float))), 0
              ) AS est_pages_ff,
              bs, nspname, tblname, idxname, relpages, fillfactor, is_na
              -- , pgstatindex(idxoid) AS pst, index_tuple_hdr_bm, maxalign, pagehdr, nulldatawidth, nulldatahdrwidth, reltuples -- (DEBUG INFO)
          FROM (
              SELECT maxalign, bs, nspname, tblname, idxname, reltuples, relpages, idxoid, fillfactor,
                    ( index_tuple_hdr_bm +
                        maxalign - CASE -- Add padding to the index tuple header to align on MAXALIGN
                          WHEN index_tuple_hdr_bm%maxalign = 0 THEN maxalign
                          ELSE index_tuple_hdr_bm%maxalign
                        END
                      + nulldatawidth + maxalign - CASE -- Add padding to the data to align on MAXALIGN
                          WHEN nulldatawidth = 0 THEN 0
                          WHEN nulldatawidth::integer%maxalign = 0 THEN maxalign
                          ELSE nulldatawidth::integer%maxalign
                        END
                    )::numeric AS nulldatahdrwidth, pagehdr, pageopqdata, is_na
                    -- , index_tuple_hdr_bm, nulldatawidth -- (DEBUG INFO)
              FROM (
                  SELECT n.nspname, i.tblname, i.idxname, i.reltuples, i.relpages,
                      i.idxoid, i.fillfactor, current_setting('block_size')::numeric AS bs,
                      CASE -- MAXALIGN: 4 on 32bits, 8 on 64bits (and mingw32 ?)
                        WHEN version() ~ 'mingw32' OR version() ~ '64-bit|x86_64|ppc64|ia64|amd64' THEN 8
                        ELSE 4
                      END AS maxalign,
                      /* per page header, fixed size: 20 for 7.X, 24 for others */
                      24 AS pagehdr,
                      /* per page btree opaque data */
                      16 AS pageopqdata,
                      /* per tuple header: add IndexAttributeBitMapData if some cols are null-able */
                      CASE WHEN max(coalesce(s.null_frac,0)) = 0
                          THEN 2 -- IndexTupleData size
                          ELSE 2 + (( 32 + 8 - 1 ) / 8) -- IndexTupleData size + IndexAttributeBitMapData size ( max num filed per index + 8 - 1 /8)
                      END AS index_tuple_hdr_bm,
                      /* data len: we remove null values save space using it fractionnal part from stats */
                      sum( (1-coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 1024)) AS nulldatawidth,
                      max( CASE WHEN i.atttypid = 'pg_catalog.name'::regtype THEN 1 ELSE 0 END ) > 0 AS is_na
                  FROM (
                      SELECT ct.relname AS tblname, ct.relnamespace, ic.idxname, ic.attpos, ic.indkey, ic.indkey[ic.attpos], ic.reltuples, ic.relpages, ic.tbloid, ic.idxoid, ic.fillfactor,
                          coalesce(a1.attnum, a2.attnum) AS attnum, coalesce(a1.attname, a2.attname) AS attname, coalesce(a1.atttypid, a2.atttypid) AS atttypid,
                          CASE WHEN a1.attnum IS NULL
                          THEN ic.idxname
                          ELSE ct.relname
                          END AS attrelname
                      FROM (
                          SELECT idxname, reltuples, relpages, tbloid, idxoid, fillfactor, indkey,
                              pg_catalog.generate_series(1,indnatts) AS attpos
                          FROM (
                              SELECT ci.relname AS idxname, ci.reltuples, ci.relpages, i.indrelid AS tbloid,
                                  i.indexrelid AS idxoid,
                                  coalesce(substring(
                                      array_to_string(ci.reloptions, ' ')
                                      from 'fillfactor=([0-9]+)')::smallint, 90) AS fillfactor,
                                  i.indnatts,
                                  pg_catalog.string_to_array(pg_catalog.textin(
                                      pg_catalog.int2vectorout(i.indkey)),' ')::int[] AS indkey
                              FROM pg_catalog.pg_index i
                              JOIN pg_catalog.pg_class ci ON ci.oid = i.indexrelid
                              WHERE ci.relam=(SELECT oid FROM pg_am WHERE amname = 'btree')
                              AND ci.relpages > 0
                          ) AS idx_data
                      ) AS ic
                      JOIN pg_catalog.pg_class ct ON ct.oid = ic.tbloid
                      LEFT JOIN pg_catalog.pg_attribute a1 ON
                          ic.indkey[ic.attpos] <> 0
                          AND a1.attrelid = ic.tbloid
                          AND a1.attnum = ic.indkey[ic.attpos]
                      LEFT JOIN pg_catalog.pg_attribute a2 ON
                          ic.indkey[ic.attpos] = 0
                          AND a2.attrelid = ic.idxoid
                          AND a2.attnum = ic.attpos
                    ) i
                    JOIN pg_catalog.pg_namespace n ON n.oid = i.relnamespace
                    JOIN pg_catalog.pg_stats s ON s.schemaname = n.nspname
                                              AND s.tablename = i.attrelname
                                              AND s.attname = i.attname
                    GROUP BY 1,2,3,4,5,6,7,8,9,10,11
              ) AS rows_data_stats
          ) AS rows_hdr_pdg_stats
        ) AS relation_stats
      )

      SELECT
        current_database,
        schemaname,
        tblname,
        idxname,
        pg_size_pretty(real_size::bigint) as real_size,
        pg_size_pretty(extra_size::bigint) as extra_size,
        round(extra_pct) as extra_pct,
        round(bloat_pct) as bloat_pct,
        pg_size_pretty(bloat_size::bigint) as bloat_size_pretty,
        bloat_size,
        fillfactor
      from
        results
      WHERE
        NOT is_na
        AND schemaname not in ('information_schema', 'pg_catalog')
        AND bloat_size > #{SIZE_CUTOFF}
        -- fillfactor is purposeful bloat/wasted space so subtract it out
        AND (bloat_pct - (100 - fillfactor)) >= #{BLOAT_CUTOFF}
      ORDER BY
        bloat_size desc
    SQL
  end

  # Dead rows and whether an automatic vacuum is expected to be triggered
  def vacuum_stats_common_table_sql_snippet
    <<~SQL
      vacuum_table_opts AS (
        SELECT
          pg_class.oid, relname, nspname, array_to_string(reloptions, '') AS relopts
        FROM
           pg_class INNER JOIN pg_namespace ns ON relnamespace = ns.oid
      ),
      vacuum_settings AS (
        SELECT
          oid, relname, nspname,
          CASE
            WHEN relopts LIKE '%autovacuum_vacuum_threshold%'
              THEN substring(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*')::integer
              ELSE current_setting('autovacuum_vacuum_threshold')::integer
            END AS autovacuum_vacuum_threshold,
          CASE
            WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%'
              THEN substring(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*')::real
              ELSE current_setting('autovacuum_vacuum_scale_factor')::real
            END AS autovacuum_vacuum_scale_factor,
          CASE
            WHEN relopts LIKE '%autovacuum_analyze_threshold%'
              THEN substring(relopts, '.*autovacuum_analyze_threshold=([0-9.]+).*')::integer
              ELSE current_setting('autovacuum_analyze_threshold')::integer
            END AS autovacuum_analyze_threshold,
          CASE
            WHEN relopts LIKE '%autovacuum_analyze_scale_factor%'
              THEN substring(relopts, '.*autovacuum_analyze_scale_factor=([0-9.]+).*')::real
              ELSE current_setting('autovacuum_analyze_scale_factor')::real
            END AS autovacuum_analyze_scale_factor
        FROM
          vacuum_table_opts
      ),
      vacuum_results AS (
        SELECT
          vacuum_settings.nspname AS schemaname,
          vacuum_settings.relname AS tblname,
          psut.last_vacuum AS last_vacuum,
          psut.last_autovacuum AS last_autovacuum,
          pg_class.reltuples AS rowcount,
          psut.n_dead_tup AS dead_rowcount,
          autovacuum_vacuum_scale_factor,
          autovacuum_vacuum_threshold,
          autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) AS autovacuum_threshold,
          autovacuum_analyze_scale_factor,
          autovacuum_analyze_threshold,
          CASE
            WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup
            THEN true
            ELSE false
          END AS expect_autovacuum,
          n_live_tup AS estimated_num_rows,
          last_autoanalyze,
          last_analyze,
          n_mod_since_analyze AS "rows_changed_since_last_analyze",
          -- for non-tiny tables, find percentage of rows modified since the last analyze
          CASE WHEN n_live_tup > 1000 THEN round(n_mod_since_analyze::numeric / n_live_tup::numeric * 100.0, 1) ELSE 0 END AS percent_unanalyzed
        FROM
          pg_stat_user_tables psut
          INNER JOIN pg_class ON psut.relid = pg_class.oid
          INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
      )
    SQL
  end

  def unused_indexes
    always_run(unused_indexes_sql)
  end

  def unused_indexes_sql
    <<~SQL
      -- Unused and almost unused indexes
      -- Ordered by their size relative to the number of index scans.
      -- Exclude indexes of very small tables (less than 5 pages),
      -- where the planner will almost invariably select a sequential scan,
      -- but may not in the future as the table grows

      -- New indexes might not have been used yet. Reindexing zeros out the
      -- stats too (it's technially a new index)
      WITH recent_indexes AS (
        SELECT
          a.indexrelid, a.relname, a.indexrelname
        FROM
          pg_stat_user_indexes a
          JOIN pg_index b ON (b.indexrelid = a.indexrelid)
        WHERE
          b.indisvalid = true -- only valid indexes
          AND indexrelname not like '%ccnew%' -- valid but not swapped in?
        ORDER BY
          a.indexrelid DESC
        LIMIT 10
      )

      SELECT
        schemaname || '.' || ui.relname AS table,
        ui.indexrelname AS index,
        pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
        idx_scan as index_scans
      FROM
        pg_stat_user_indexes ui
        JOIN pg_index i ON ui.indexrelid = i.indexrelid
        LEFT JOIN recent_indexes ri ON ( ri.indexrelname = ui.indexrelname )
      WHERE
        NOT i.indisunique -- ignore unique indexes which serve an additional purpose of ensuring uniqueness
        AND ui.indexrelname NOT LIKE 'pg_toast_%'
        AND ui.idx_scan = 0
        AND ui.idx_tup_read = 0
        AND ui.idx_tup_fetch = 0
        AND idx_scan < 50 -- ignore indexes being used (used more than 50 times)
        AND pg_relation_size(relid) > 5 * 8192 -- ignore 5 pages or less indexes
        AND pg_relation_size(i.indexrelid) > #{MIN_UNUSED_INDEX_SIZE}
        AND ri.indexrelname IS NULL -- filter out recently added or reindexed indexes
      ORDER BY
        pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST,
        pg_relation_size(i.indexrelid) DESC;
    SQL
  end

  def cache_hit_rates
    always_run(cache_hit_rates_sql)
  end

  def cache_hit_rates_sql
    <<~SQL
      -- Index and table hit rate
      SELECT
        current_database(),
        'index hit rate' AS name,
        round((sum(idx_blks_hit)) / nullif(sum(idx_blks_hit + idx_blks_read),0), 2) AS ratio
      FROM pg_statio_user_indexes
      UNION ALL
      SELECT
        current_database(),
       'table hit rate' AS name,
        sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read),0) AS ratio
      FROM pg_statio_user_tables;
    SQL
  end
end
