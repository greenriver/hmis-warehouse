require 'roo'
require 'memoist'

# Plan All-Cause Readmissions (PCR) Risk Calculator
#
# Comments reference instructions from MassHealth updated with the
# "2021 Quality Rating System Measure Technical Specifications"
# https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
# "Calculating the Plan All-Cause Readmissions (PCR) Measure in the 2021 Adult and Health Home Core Sets"
# Technical Assistance Resource
# https://www.medicaid.gov/medicaid/quality-of-care/downloads/pcr-ta-resource.pdf
# Both As of May 28, 2021
module ClaimsReporting::Calculators
  class PcrRiskAdjustment
    extend Memoist

    def initialize
      # these is kept outside of source. ANd
      @pcr_xlsx = Rails.root.join('tmp/20191101_PCR-Risk-Adjustment-Tables_HEDIS-2020.xlsx')
      @shared_xlsx = Rails.root.join('tmp/20191101_Shared-Tables_All-Risk-Adjusted-Measures_HEDIS-2020.xlsx')
    end

    # https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
    # "Risk Adjustment Comorbidity Category Determination"

    # Lookup HCC comorbidity categores based on DX codes
    # dx_codes:
    #
    # > Step 1 Identify all diagnoses for encounters during the classification period. Include the following
    # > when identifying encounters:
    # > • Outpatient visits (Outpatient Value Set).
    # > • Telephone visits (Telephone Visits Value Set)
    # > • Observation visits (Observation Value Set).
    # > • ED visits (ED Value Set).
    # > • Inpatient events:
    # > – Nonacute inpatient encounters (Nonacute Inpatient ValueSet).
    # > – Acute inpatient encounters (Acute Inpatient Value Set).
    # > – Acute and nonacute inpatient discharges (Inpatient Stay ValueSet).
    # > Use the date of service for outpatient, observation and ED visits.
    # > Use the discharge date for inpatient events.
    # > Exclude the primary discharge diagnosis on the IHS.

    # With 2020 data, you can test with %w/G8320 E0852 A0104/ to trigger
    # the edge cases of
    # - a DX mapping to multiple CCs
    # - a CC mapping to HCCs in multiple ranking groups with different ranks
    # - a CC with no HCC mappings

    def calculate_hcc_codes(dx_codes)
      # > Step 2 Assign each diagnosis to a comorbid Clinical Condition (CC) category using
      # > Table CC—Comorbid. If the code appears more than once in Table CC—Comorbid,
      # > it is assigned to multiple CCs.
      # >
      # > Exclude all diagnoses that cannot be assigned to a comorbid CC category.
      # > All digits must match exactly when mapping diagnosis codes to the comorbid CCs.
      cc_codes = dx_codes.flat_map { |dx| cc_comorbid[dx] }.compact.uniq

      # > For members with no qualifying diagnoses from face-to-face encounters,
      # > skip to the Risk Adjustment Weighting section.
      return [] unless cc_codes.any?

      # > Step 3 Determine HCCs for each comorbid CC identified. Refer to Table HCC—Rank.
      hcc_rows = []
      # > For each encounter’s comorbid CC list, match the comorbid CC code to the comorbid CC code
      # > in the table, and assign: The ranking group, The rank, The HCC.
      # > Note: One comorbid CC can map to multiple HCCs; each HCC can have one or more comorbid CCs.
      cc_codes.each do |cc_code|
        hcc_codes = table_hcc_rank[cc_code]
        if hcc_codes
          hcc_rows += hcc_codes
        else
          # > For comorbid CCs that do not match to Table HCC—Rank, use the comorbid CC as the HCC
          # > and assign a rank of 1.
          hcc_rows << {
            ranking_group: 'Unmatched CC',
            cc: cc_code,
            hcc: cc_code,
            rank: 1,
          }
        end
      end

      # > Step 4 Assess each ranking group separately and select only the highest ranked HCC in each ranking
      # > group using the Rank column (1 is the highest rank possible).
      # > Drop all other HCCs in each ranking group, and de-duplicate the HCC list if necessary.
      ranking_groups = hcc_rows.group_by do |row|
        row[:ranking_group]
      end

      ranking_groups.values.map do |group_rows|
        group_rows.min_by { |r| r[:rank] }[:hcc]
      end.uniq
    end

    # returns a Hash of various calculated components based on attributes
    # of the Index Health Stay
    # can raise if we are unable to load the XLSX file containing risk lookup data
    def process_ihs(
      age:, # Integer age
      gender:, # Biological Sex: 'Male' or 'Female' (also accepts 'm' or 'f' or similar variants)
      had_surgery:, # true if the patient had surgery during the stay
      discharge_dx_code:, # the primary discharge diagnosis on the IHS
      comborb_dx_codes: # all diagnoses for encounters during the classification period excluding the primary discharge diagnosis on the IHS
    )
      # For each IHS, use the following steps to identify risk adjustment weights based on presence of surgeries, discharge condition, comorbidity, age and gender.

      # 1. For each IHS with a surgery, link the surgery weight. Use Table PCR-MD-OtherWeights.
      surg_weight = pcr_md_other_weights['Surgery'] if had_surgery # example table shows NA for members without a surgery

      # 2. For each IHS with a discharge CC Category, link the primary discharge weights. Use Table PCR-MD-DischCC-Weight.
      discharge_cc = pcr_dischcc[discharge_dx_code] # exclude dx note included
      discharge_weight = (pcr_md_dischcc_weights[discharge_cc] || 0) if discharge_cc # NOTE: CCs not listed receive a weight of ZERO (i.e., 0.0000).

      # 3. For each IHS with a comorbidity HCC Category, link the weights. Use Table PCR-MD-ComorbHCC-Weight.
      hcc_codes = calculate_hcc_codes(comborb_dx_codes)
      hcc_weights = hcc_codes.map do |hcc_code|
        pcr_md_comorbhcc_weights[hcc_code]
      end

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
        discharge_dx_code: discharge_dx_code,
        discharge_cc: discharge_cc,
        discharge_weight: discharge_weight,
        comborb_dx_codes: comborb_dx_codes,
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

    private def shared_roo
      ::Roo::Excelx.new(@shared_xlsx)
    end
    memoize :shared_roo

    private def pcr_roo
      ::Roo::Excelx.new(@pcr_xlsx)
    end
    memoize :pcr_roo

    def cc_comorbid
      shared_roo.sheet('Table CC-Comorbid').parse(
        clean: true,
        icd_version: 'ICD Version',
        dx_code: 'Diagnosis Code',
        cc: 'Comorbid_CC',
      ).group_by do |row|
        row[:dx_code]
      end.transform_values do |rows|
        rows.map { |r| r[:cc] }
      end
    end
    memoize :cc_comorbid

    def table_hcc_rank
      shared_roo.sheet('Table HCC-Rank').parse(
        clean: true,
        ranking_group: 'Ranking Group',
        cc: 'CC',
        description: 'Description',
        rank: 'Rank',
        hcc: 'HCC',
      ).group_by do |r|
        r[:cc]
      end
    end

    def hcc_surg
      pcr_roo.sheet('HCC-Surg').parse(
        clean: true,
        procedure_code: 'Procedure Code',
      ).map do |row|
        row[:procedure_code]
      end.compact.to_set
    end

    def pcr_dischcc
      pcr_roo.sheet('PCR-DischCC').parse(
        clean: true,
        dx_code: 'Diagnosis Code',
        cc: 'Comorbid_CC',
      ).map do |row|
        [row[:dx_code], row[:cc]]
      end.to_h.compact
    end
    memoize :pcr_dischcc

    def pcr_md_dischcc_weights
      pcr_roo.sheet('PCR-MD-DischCC-Weight').parse(
        clean: true,
        category: 'PCR-CC Category (Risk Marker)',
        weight: 'PCR-CC Weight',
      ).map do |row|
        [row[:category], row[:weight]]
      end.to_h.compact
    end
    memoize :pcr_md_dischcc_weights

    def pcr_md_comorbhcc_weights
      pcr_roo.sheet('PCR-MD-ComorbHCC-Weight').parse(
        clean: true,
        category: 'PCR-HCC Category (Risk Marker)',
        weight: 'PCR-HCC Weight',
      ).map do |row|
        [row[:category], row[:weight]]
      end.to_h.compact
    end
    memoize :pcr_md_comorbhcc_weights

    def pcr_md_other_weights
      pcr_roo.sheet('PCR-MD-OtherWeights').parse(
        clean: true,
        category: 'Description',
        weight: 'PCR Weight',
      ).map do |row|
        [row[:category], row[:weight]]
      end.to_h.compact
    end
    memoize :pcr_md_other_weights
  end
end
