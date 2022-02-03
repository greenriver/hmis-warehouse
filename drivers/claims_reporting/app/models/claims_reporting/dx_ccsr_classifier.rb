###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'
require 'progress_bar'

module ClaimsReporting
  class DxCcsrClassifier
    attr_reader :unknown_codes

    def initialize
      @unknown_codes = Hash.new(0)
    end

    RX_EXTRA_QUOTING = /(\A')|('\Z)/.freeze

    def self.load_csv(file)
      data = {}
      # the source file adds single quotes around most codes
      # and we understand blanks to be nil
      remove_extra_quoting = lambda do |v|
        v.gsub(RX_EXTRA_QUOTING, '').presence
      rescue StandardError
        v
      end
      logger.info { "Loading #{file}" }
      CSV.foreach(file,
                  row_sep: :auto,
                  headers: true,
                  quote_char: %("),
                  converters: [remove_extra_quoting],
                  header_converters: [remove_extra_quoting]) do |row|
        icd10cm = row['ICD-10-CM CODE'].freeze
        if icd10cm.present?
          data[icd10cm] = [
            row['CCSR CATEGORY 1'],
            row['CCSR CATEGORY 2'],
            row['CCSR CATEGORY 3'],
            row['CCSR CATEGORY 4'],
            row['CCSR CATEGORY 5'],
            row['CCSR CATEGORY 6'],
          ].compact.map(&:freeze).freeze
        end
      end
      logger.info { "Loaded #{file}" }
      GC.start # CSV import will leave a ton of strings layout around we dont need
      data
    end

    # a lazy-loaded process global lookup table
    def self.lookup_table
      @lookup_table ||= load_csv(Rails.root.join('db/health/DXCCSR_v2021-1.csv'))
    end

    def lookup_table
      self.class.lookup_table
    end

    DX_COLS = [
      'dx_1', 'dx_2', 'dx_3', 'dx_4', 'dx_5', 'dx_6', 'dx_7', 'dx_8', 'dx_9', 'dx_10',
      'dx_11', 'dx_12', 'dx_13', 'dx_14', 'dx_15', 'dx_16', 'dx_17', 'dx_18', 'dx_19',
      'dx_20', 'dx_21', 'dx_22', 'dx_23', 'dx_24', 'dx_25'
    ].freeze

    # Look up a claim (calling lookup_icd10cm for each code found in DX_COLS)
    # increments a counter unknown_codes for each code it could not find
    def lookup_claim(claim)
      all_ccsrs = Set.new
      DX_COLS.each do |col|
        ccsrs = lookup_icd10cm(claim[col])
        all_ccsrs += ccsrs if ccsrs.present?
      end
      all_ccsrs
    end

    # Looks up a single icd10cm code
    # increments a counter unknown_codes for each code it could not find
    def lookup_icd10cm(icd10cm)
      return unless icd10cm.present?

      # sometimes we get a category cand
      # CCSR lists it under the zeroth factional code
      icd10cm = icd10cm.to_s

      # FIXME?: DXCCSR-User-Guide-v2021-1.pdf Page 24 says we CANNOT do this
      # orginal = icd10cm
      # ccsrs = nil
      # but we end up with a bunch of data that seems like it should match
      # while icd10cm.length < 7 do
      #   ccsrs = lookup_table[icd10cm]
      #   break if ccsrs.present?
      #   icd10cm = "#{icd10cm}0"
      #   puts "trying #{icd10cm} for #{orginal}"
      # end
      # e.g. from a recent sample file we had 210 "R4585" codes which should have been billed as be "R45850"
      ccsrs = lookup_table[icd10cm]
      unless ccsrs.present?
        # logger.warn { "ICD-10-CM: #{icd10cm} has no mapping to CCSR"}
        unknown_codes[icd10cm] += 1
      end
      ccsrs
    end

    def classify_medical_claims(scope = ClaimsReporting::MedicalClaim.all, use_pb: true)
      lookup_table

      pb = ProgressBar.new(scope.count) if use_pb
      max_codes = 0
      scope.logger.silence(Logger::INFO) do
        scope.select(:id, *DX_COLS).in_batches do |batch|
          updates = batch.map do |claim|
            pb&.increment!
            ccsrs_for_claim = lookup_claim(claim)
            max_codes = ccsrs_for_claim.size if ccsrs_for_claim.size > max_codes
            {
              id: claim.id,
              ccsrs: ccsrs_for_claim,
            }
          end
          # TODO: scope.import(updates, on_duplicate_key_update: { conflict_target: [:id], columns: [:ccs_id] })
        end
      end
      puts "unknown_codes: #{JSON.generate unknown_codes}"
      puts "max_codes: #{max_codes}"
    end

    # def self.report_memory
    #   return yield unless Rails.env.development?
    #   res = nil
    #   report = MemoryProfiler.report do
    #     puts "a"
    #     res = yield
    #     puts "b"
    #   end
    #   puts report.pretty_print
    #   res
    # end

    # def report_memory
    #   self.class.report_memory
    # end

    def self.logger
      Rails.logger
    end

    private def logger
      self.class.logger
    end
  end
end
