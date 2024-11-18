###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks::ScrubPii
  # Scrub personally identifiable information (PII) from all warehouse and reporting tables
  class ScrubAllPiiTask
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
        # misc
        TextMessage::TopicSubscriber,
        GrdaWarehouse::HealthEmergency::UploadedTest,
        GrdaWarehouse::Contact::Base,
        GrdaWarehouse::Hmis::Staff,
        GrdaWarehouse::HmisClient,
        # warehouse.ClientUnencrypted, # no model?

        # hud records
        GrdaWarehouse::Hud::Client,
        GrdaWarehouse::Hud::User,
        Hmis::Hud::CustomClientAddress,
        Hmis::Hud::CustomClientName,
        Hmis::Hud::CustomClientContactPoint,
        Hmis::Hud::CustomCaseNote,
        Hmis::Hud::CustomDataElement,

        # reports
        HudApr::Fy2020::AprClient,
        HomelessSummaryReport::Client,
        HudDataQualityReport::Fy2020::DqClient,
        HudPathReport::Fy2020::PathClient,
        HudSpmReport::Fy2020::SpmClient,
        IncomeBenefitsReport::Client,
        MaYyaReport::Client,
        HudSpmReport::Fy2023::SpmEnrollment,
        GrdaWarehouse::AdHocClient,
        CePerformance::Client,
        GrdaWarehouse::ClientContact,
        Financial::Client,
        HmisDataQualityTool::Client,
        HmisDataQualityTool::Enrollment,
        HudPit::Fy2022::PitClient,
        HudReports::UniverseMember,
        MaReports::MonthlyPerformance::Enrollment,
        PerformanceMetrics::Client,
        ProjectPassFail::Client,
        SimpleReports::UniverseMember,

        # reporting db
        Reporting::Housed,
        Reporting::DataQualityReports::Enrollment,

        HmisCsvTwentyTwenty::Importer::Client,
        HmisCsvTwentyTwenty::Importer::User,
        HmisCsvTwentyTwenty::Loader::Client,
        HmisCsvTwentyTwenty::Loader::User,

        HmisCsvTwentyTwentyTwo::Importer::Client,
        HmisCsvTwentyTwentyTwo::Importer::User,
        HmisCsvTwentyTwentyTwo::Loader::Client,
        HmisCsvTwentyTwentyTwo::Loader::User,

        HmisCsvTwentyTwentyFour::Importer::Client,
        HmisCsvTwentyTwentyFour::Importer::User,
        HmisCsvTwentyTwentyFour::Loader::Client,
        HmisCsvTwentyTwentyFour::Loader::User,
      ]
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
