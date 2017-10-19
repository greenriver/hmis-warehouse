module Health::Claims
  class ViewModel

    include ActionView::Helpers::NumberHelper

    def initialize(patient, sdh_rosters)
      @patient = patient
      @patient_roster = patient.claims_roster
      @sdh_rosters = sdh_rosters
    end

    def cost_table
      result = {patient: {}, sdh: {}, variance: {}}
      if @patient_roster.present?
        values = load_patient_sdh_variance(load_cost_values)
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
        values = load_patient_sdh_variance(load_key_metric_values)
        values.each_with_index do |v, index|
          key = result.keys[index]
          result[key] = {
            Normalized_Risk: display_value(key, v[0], v[0]), 
            ED_Visits: display_value(key, v[1], v[1]), 
            IP_Admits: display_value(key, v[2], v[2]), 
            Average_Days_to_Readmit: display_value(key, v[3], v[3])
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
          ['Primary Care Physician', @patient.primary_care_physician],
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

    def load_patient_sdh_variance(values)
      patient, sdh = values
      variance = patient.each_with_index.map do |p, i|
        sdh_variance(p, sdh[i])
      end
      [patient, sdh, variance]
    end

    def load_key_metric_values
      patient = [
        @patient_roster.norm_risk_score.round(1), 
        @patient_roster.ed_visits, 
        @patient_roster.acute_ip_admits,
        @patient_roster.average_days_to_readmit 
      ]
      sdh = [
        sdh_avg(@sdh_rosters.map(&:norm_risk_score)).round(1),
        sdh_avg(@sdh_rosters.map(&:ed_visits)).round(),
        sdh_avg(@sdh_rosters.map(&:acute_ip_admits)).round(),
        sdh_avg(@sdh_rosters.map(&:average_days_to_readmit)).round()
      ]
      [patient, sdh]
    end

    def load_cost_values
      patient = [
        @patient_roster.total_ty.round(), 
        @patient_roster.mbr_months
      ]
      sdh = [
        sdh_avg(@sdh_rosters.all.map(&:total_ty)).round(),
        sdh_avg(@sdh_rosters.all.map(&:mbr_months)).round(1) 
      ]
      [patient, sdh].each do |arry|
        arry.push((arry[0]/arry[1].to_f).round())
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

    def sdh_variance(patient, sdh)
      if patient && sdh
        (((patient - sdh)/sdh.to_f)*100).round()
      else
        'N/A'
      end
    end

  end
end