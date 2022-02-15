###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: View model. Refers to PHI related models thru their documents public interfaces.
# Controls should be implemented there
module Health::Claims
  class ViewModel

    include ActionView::Helpers::NumberHelper

    def initialize(patient, sdh_rosters)
      @patient = patient
      @patient_roster = patient&.claims_roster
      @sdh_rosters = sdh_rosters
    end

    def cost_table
      result = {patient: {}, sdh: {}, variance: {}}
      if @patient_roster.present?
        values = load_implementation_baseline_variance(load_cost_values)
        values.each_with_index do |v, index|
          key = result.keys[index]
          result[key] = {
            Total_Cost: display_value(key, v[0], number_to_currency(v[0], precision: 0)),
            Months: display_value(key, v[1], v[1]),
            Cost_PMPM: display_value(key, v[2], number_to_currency(v[2], precision: 0))
          }
        end
      end
      load_table(result)
    end

    def key_metrics_table
      result = {patient: {}, sdh: {}, variance: {}}
      if @patient_roster.present?
        values = load_implementation_baseline_variance(load_key_metric_values)
        values.each_with_index do |v, index|
          key = result.keys[index]
          result[key] = {
            ED_Visits: display_value(key, v[0], v[0]),
            IP_Admits: display_value(key, v[1], v[1]),
            Average_Days_to_Readmit: display_value(key, v[2], v[2])
          }
        end
      end
      load_table(result)
    end

    def patient_summary
      result = {details: [], demographics: []}
      if @patient.present?
        if @patient_roster.present?
          team = @patient_roster.epic_team
          disability_flag = @patient_roster.disability_flag ? 'Y' : 'N'
        else
          team = 'Unknown'
          disability_flag = 'Unknown'
        end
        result[:details] = [
          ['SSN', @patient.ssn],
          ['Medicaid ID', @patient.medicaid_id],
          ['Primary Care Provider', @patient.primary_care_physician],
          ['Assignment Date', @patient.enrollment_start_date],
          # ['Team', team]
        ]
        result[:demographics].push([
          ['Age', @patient.client.age],
          ['Gender', @patient.gender],
          ['Disability Flag', disability_flag],
        ])
        result[:demographics].push([
          ['DOB', @patient.birthdate],
          ['Race / Ethnicity', "#{@patient.race} / #{@patient.ethnicity}"],
          ['Veteran Status', @patient.veteran_status]
        ])
      end
      result
    end

    protected

    def load_table(result)
      Struct.new('Table', :keys, :patient, :sdh, :variance)
      Struct::Table.new(result[:patient].keys, result[:patient], result[:sdh], result[:variance])
    end

    def load_implementation_baseline_variance(values)
      implementation, baseline = values
      variance = implementation.each_with_index.map do |p, i|
        baseline_variance(p, baseline[i])
      end
      [implementation, baseline, variance]
    end

    def load_key_metric_values
      implementation_months = @patient_roster.member_months_implementation
      baseline_months = @patient_roster.member_months_baseline
      implementation_ave_ed_visits = @patient.ed_nyu_severities.sum(:implementation_visits).to_f / implementation_months rescue 0
      baseline_ave_ed_visits = @patient.ed_nyu_severities.sum(:baseline_visits).to_f / baseline_months rescue 0
      implementation_ip_admit_ave = @patient_roster.implementation_admits.to_f / implementation_months rescue 0
      baseline_ip_admit_ave = @patient_roster.baseline_admits.to_f / baseline_months rescue 0
      implementation = [
        implementation_ave_ed_visits&.round(1),
        implementation_ip_admit_ave&.round(1),
        @patient_roster.average_days_to_implementation&.round(),
      ]
      baseline = [
        baseline_ave_ed_visits&.round(1),
        baseline_ip_admit_ave&.round(1),
        @patient_roster.average_days_to_readmit_baseline&.round(),
      ]
      [implementation, baseline]
    end

    def load_cost_values
      implementation_sum = @patient.amount_paids.implementation.map(&:total).sum&.round() rescue 0
      implementation_count = @patient.amount_paids.implementation.map(&:total).count&.round()
      patient = [
        implementation_sum,
        implementation_count,
      ]
      baseline_sum = @patient.amount_paids.baseline.map(&:total).sum&.round() rescue 0
      baseline_count = @patient.amount_paids.baseline.map(&:total).count&.round() rescue 0
      sdh = [
        baseline_sum,
        baseline_count,
      ]
      [patient, sdh].each do |arry|
        arry.push((arry[0]/arry[1].to_f).round()) rescue 0
      end
      [patient, sdh]
    end

    def display_value(key, value, formattedValue)
      if value.present?
        key == :variance ? "#{value}%" : formattedValue
      else
        'N/A'
      end
    end

    def sdh_avg(values)
      values = values.compact
      (values.inject(0){|sum, v| sum+v})/values.size.to_f
    end

    def baseline_variance(implementation, baseline)
      if implementation && baseline && baseline != 0
        (((implementation - baseline)/baseline.to_f)*100).round() rescue 'N/A'
      else
        'N/A'
      end
    end

  end
end
