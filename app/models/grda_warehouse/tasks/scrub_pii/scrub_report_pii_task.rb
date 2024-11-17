###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ScrubPii
  # Responsible for scrubber personally identifiable information (PII) from report records.
  class ScrubReportPiiTask
    def self.perform(...)
      new.perform(...)
    end

    def perform(...)
      with_lock do
        scrubber = GrdaWarehouse::Tasks::ScrubPii::ScrubModelPii.new(...)
        models.each do |model|
          scrubber.perform(model.unscoped)
        end
      end
    end

    protected

    def models
      [
        # hud records
        GrdaWarehouse::Hud::Client,
        # custom hmis data
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientName,
        Hmis::Hud::CustomClientContactPoint,
        Hmis::Hud::CustomCaseNote,
        Hmis::Hud::CustomDataElement,
        #reports
        HudApr::Fy2020::AprClient,
        HapReport::HapClient,
        # HomelessSummaryReport::Client,
        # HudDataQualityReport::Fy2020::DqClient,
        # HudPathReport::Fy2020::PathClient,
        # HudSpmReport::Fy2020::SpmClient,
        # IncomeBenefitsReport::Client,
        # MaYyaReport::Client,
        # check for enrollment, "SimpleReports::ReportInstance", anything inheriting from ReportingBase
      ]
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
