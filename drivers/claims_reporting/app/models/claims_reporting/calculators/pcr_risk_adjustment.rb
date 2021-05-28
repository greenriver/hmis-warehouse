require 'roo'
require 'memoist'

# Plan All-Cause Readmissions (PCR) Risk Calculator
#
# Comments reference instructions from MassHealth updated with the
# "Calculating the Plan All-Cause Readmissions (PCR) Measure in the 2021 Adult and Health Home Core Sets"
# Technical Assistance Resource
# Downloaded May 28, 2021 from
# https://www.medicaid.gov/medicaid/quality-of-care/downloads/pcr-ta-resource.pdf

module ClaimsReporting::Calculators
  class PcrRiskAdjustment
    extend Memoist

    def initialize
      # this is kept outside of source. It's under separate license
      @xlsx_path = Rails.root.join('tmp/20191101_PCR-Risk-Adjustment-Tables_HEDIS-2020.xlsx')
    end

    # returns a Hash of various calculated components based on the input claim data
    # can raise if we are unable to load the XLSX file containing risk lookup data
    def process_claim(
      age:,
      gender:,
      had_surgery:,
      dx_1:
    )
      # For each IHS, use the following steps to identify risk adjustment weights based on presence of surgeries, discharge condition, comorbidity, age and gender.

      # 1. For each IHS with a surgery, link the surgery weight. Use Table PCR-MD-OtherWeights.
      surg_weight = pcr_md_other_weights['Surgery'] if had_surgery # example table shows NA for members without a surgery

      # 2. For each IHS with a discharge CC Category, link the primary discharge weights. Use Table PCR-MD-DischCC-Weight.
      discharge_cc = pcr_dischcc[dx_1] # exclude dx note included
      discharge_weight = (pcr_md_dischcc_weights[discharge_cc] || 0) if discharge_cc # NOTE: CCs not listed receive a weight of ZERO (i.e., 0.0000).

      # 3. For each IHS with a comorbidity HCC Category, link the weights. Use Table PCR-MD-ComorbHCC-Weight.
      hcc_codes = [] # FIXME
      hcc_weights = [] # FIXME

      # 4. Link the age and gender weights for each IHS. Use Table PCR-MD-OtherWeights.
      age_gender_weight = lookup_age_gender_weight(age, gender)

      # 5. Identify the base risk weight. Use Table PCR-MD-OtherWeights to determine the base risk weight.
      # Base weights are no longer used per
      # https://www.iha.org/wp-content/uploads/2020/10/Measurement-Year-MY-2019-AMP-Program-Manual.pdf

      # 6. Sum all weights associated with the IHS (i.e., presence of surgery, primary discharge
      # diagnosis, comorbidities, age, gender and base risk weight) and use the formula below
      # to calculate the Estimated Readmission Risk for each IHS.
      sum_of_weights = ([
        surg_weight,
        discharge_weight,
        age_gender_weight,
      ] + hcc_weights).compact.sum

      # Estimated Readmission Risk = [exp (sum of weights for IHS)] / [ 1 + exp (sum of weights for IHS)]
      x = Math.exp(sum_of_weights)
      expected_readmit_rate = x / (1 + x)

      # 7. Calculate the Count of Expected Readmissions. The Count of Expected Readmissions
      # is the sum of the Estimated Readmission Risk calculated in step 6 for each IHS.
      # TODO

      # 8. Use the formula below and the Expected Readmissions Rate calculated in step 6 to calculate the variance for each IHS.
      variance = expected_readmit_rate * (1 - expected_readmit_rate)

      {
        age: age,
        gender: gender,
        age_gender_weight: age_gender_weight,
        had_surgery: had_surgery,
        surg_weight: surg_weight,
        dx_1: dx_1,
        discharge_cc: discharge_cc,
        discharge_weight: discharge_weight,
        hcc_codes: hcc_codes,
        hcc_weights: hcc_weights,
        sum_of_weights: sum_of_weights,
        expected_readmit_rate: expected_readmit_rate,
        variance: variance,
      }
    end

    def lookup_age_gender_weight(age, gender)
      age_bucket = case age
      when 18..44 then '18-44'
      when 45..54 then '45-54'
      when 55..64 then '55-64'
      else; 'Unknown'
      end

      gender_bucket = case gender
      when /^M/i then 'Male'
      when /^F/i then 'Female'
      else; 'Unknown'
      end
      key = "#{gender_bucket} #{age_bucket}"

      pcr_md_other_weights[key]
    end

    private def roo
      ::Roo::Excelx.new(@xlsx_path)
    end
    memoize :roo

    def hcc_surg
      roo.sheet('HCC-Surg').parse(
        procedure_code: 'Procedure Code',
      ).map do |row|
        row[:procedure_code].strip
      end.compact.to_set
    end

    def pcr_dischcc
      roo.sheet('PCR-DischCC').parse(
        dx_code: 'Diagnosis Code',
        cc: 'Comorbid_CC',
      ).map do |row|
        [row[:dx_code]&.strip, row[:cc]&.strip]
      end.to_h.compact
    end
    memoize :pcr_dischcc

    def pcr_md_dischcc_weights
      roo.sheet('PCR-MD-DischCC-Weight').parse(
        category: 'PCR-CC Category (Risk Marker)',
        weight: 'PCR-CC Weight',
      ).map do |row|
        [row[:category]&.strip, row[:weight]]
      end.to_h.compact
    end
    memoize :pcr_md_dischcc_weights

    def pcr_md_other_weights
      roo.sheet('PCR-MD-OtherWeights').parse(
        category: 'Description',
        weight: 'PCR Weight',
      ).map do |row|
        [row[:category]&.strip, row[:weight]]
      end.to_h.compact
    end
    memoize :pcr_md_other_weights
  end
end
