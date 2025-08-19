# frozen_string_literal: true

class PopulateAssociatedReportGenerator < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      execute <<-SQL
        UPDATE hud_report_instances
        SET generator_class_name = CASE
          WHEN report_name LIKE '%Annual Performance Report%' THEN
            CASE
              WHEN report_name LIKE '%FY 2020%' THEN 'HudApr::Generators::Apr::Fy2020::Generator'
              WHEN report_name LIKE '%FY 2021%' THEN 'HudApr::Generators::Apr::Fy2021::Generator'
              WHEN report_name LIKE '%FY 2023%' THEN 'HudApr::Generators::Apr::Fy2023::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudApr::Generators::Apr::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2026%' THEN 'HudApr::Generators::Apr::Fy2026::Generator'
              ELSE 'HudApr::Generators::Apr::Fy2024::Generator'
            END
          WHEN report_name LIKE '%Consolidated Annual Performance and Evaluation Report%' THEN
            CASE
              WHEN report_name LIKE '%FY 2020%' THEN 'HudApr::Generators::Caper::Fy2020::Generator'
              WHEN report_name LIKE '%FY 2021%' THEN 'HudApr::Generators::Caper::Fy2021::Generator'
              WHEN report_name LIKE '%FY 2023%' THEN 'HudApr::Generators::Caper::Fy2023::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudApr::Generators::Caper::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2026%' THEN 'HudApr::Generators::Caper::Fy2026::Generator'
              ELSE 'HudApr::Generators::Caper::Fy2024::Generator'
            END
          WHEN report_name LIKE '%Coordinated Entry Annual Performance Report%' THEN
            CASE
              WHEN report_name LIKE '%FY 2020%' THEN 'HudApr::Generators::CeApr::Fy2020::Generator'
              WHEN report_name LIKE '%FY 2021%' THEN 'HudApr::Generators::CeApr::Fy2021::Generator'
              WHEN report_name LIKE '%FY 2023%' THEN 'HudApr::Generators::CeApr::Fy2023::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudApr::Generators::CeApr::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2026%' THEN 'HudApr::Generators::CeApr::Fy2026::Generator'
              ELSE 'HudApr::Generators::CeApr::Fy2024::Generator'
            END
          WHEN report_name LIKE '%System Performance Measures%' THEN
            CASE
              WHEN report_name LIKE '%FY 2020%' THEN 'HudSpmReport::Generators::Fy2020::Generator'
              WHEN report_name LIKE '%FY 2023%' THEN 'HudSpmReport::Generators::Fy2023::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudSpmReport::Generators::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2026%' THEN 'HudSpmReport::Generators::Fy2026::Generator'
              ELSE 'HudSpmReport::Generators::Fy2024::Generator'
            END
          WHEN report_name LIKE '%Point in Time Count%' THEN
            CASE
              WHEN report_name LIKE '%FY 2022%' THEN 'HudPit::Generators::Pit::Fy2022::Generator'
              WHEN report_name LIKE '%FY 2023%' THEN 'HudPit::Generators::Pit::Fy2023::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudPit::Generators::Pit::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2025%' THEN 'HudPit::Generators::Pit::Fy2025::Generator'
              ELSE 'HudPit::Generators::Pit::Fy2025::Generator'
            END
          WHEN report_name LIKE '%Annual PATH Report%' THEN
            CASE
              WHEN report_name LIKE '%FY 2020%' THEN 'HudPathReport::Generators::Fy2020::Generator'
              WHEN report_name LIKE '%FY 2021%' THEN 'HudPathReport::Generators::Fy2021::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudPathReport::Generators::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2026%' THEN 'HudPathReport::Generators::Fy2026::Generator'
              ELSE 'HudPathReport::Generators::Fy2024::Generator'
            END
          WHEN report_name LIKE '%HOPWA CAPER%' THEN 'HopwaCaper::Generators::Fy2024::Generator'
          WHEN report_name LIKE '%Housing Inventory Count%' THEN 'HudHic::Generators::Hic::Fy2022::Generator'
          WHEN report_name LIKE '%Longitudinal System Analysis%' THEN 'HudLsa::Generators::Lsa::Fy2022::Generator'
          WHEN report_name LIKE '%Data Quality Report%' THEN
            CASE
              WHEN report_name LIKE '%FY 2020%' THEN 'HudDataQualityReport::Generators::Fy2020::Generator'
              WHEN report_name LIKE '%FY 2022%' THEN 'HudDataQualityReport::Generators::Fy2022::Generator'
              WHEN report_name LIKE '%FY 2024%' THEN 'HudApr::Generators::Dq::Fy2024::Generator'
              WHEN report_name LIKE '%FY 2026%' THEN 'HudApr::Generators::Dq::Fy2026::Generator'
              ELSE 'HudApr::Generators::Dq::Fy2024::Generator'
            END
          ELSE NULL
        END
        WHERE generator_class_name IS NULL
        AND report_name != 'HMIS Data Quality Tool'
      SQL
    end
  end

  def down
    HudReports::ReportInstance.update_all(generator_class_name: nil)
  end
end
