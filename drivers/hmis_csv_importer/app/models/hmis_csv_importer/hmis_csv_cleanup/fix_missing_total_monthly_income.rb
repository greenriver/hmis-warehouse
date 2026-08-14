###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::HmisCsvCleanup
  # Opt-in, off-by-default pre-ingest cleanup that fills in a missing TotalMonthlyIncome by summing the
  # individual income source amounts.
  # Only touches staging rows for the current importer_log where the record
  # indicates income (IncomeFromAnySource = 1) but has a null TotalMonthlyIncome.
  # Does not fix records where the TotalMonthlyIncome disagrees with the individual income source amounts.
  class FixMissingTotalMonthlyIncome < Base
    def cleanup!
      Hmis::Hud::DataIntegrity::TotalIncomeReconciler.new.fill_missing_totals!(
        scope: income_benefit_scope,
        conflict_target: conflict_target(income_benefit_source), # todo @martha - understand this better
      )
    end

    def income_benefit_scope
      income_benefit_source.where(importer_log_id: @importer_log.id)
    end

    def income_benefit_source
      importable_file_class('IncomeBenefit')
    end

    def self.description
      'Fill in missing TotalMonthlyIncome by summing income source amounts'
    end

    def self.enable
      {
        import_cleanups: {
          'IncomeBenefit': ['HmisCsvImporter::HmisCsvCleanup::FixMissingTotalMonthlyIncome'],
        },
      }
    end
  end
end
