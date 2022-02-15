###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
require 'memoist'

# Latest Plan All-Cause Readmissions (PCR) Risk Calculator
#
# Note: the algorithm, reference data format and weights all changed
# in each of the first 3 years of the Community Partners Program.
# If year specific models are needed it probably makes sense to implement
# in separate classes with a similar interface and a factory pattern
#
# Comments reference instructions from MassHealth (our original spec) updated with the
# "2021 Quality Rating System Measure Technical Specifications"
# https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
# "Calculating the Plan All-Cause Readmissions (PCR) Measure in the 2021 Adult and Health Home Core Sets"
# Technical Assistance Resource
# https://www.medicaid.gov/medicaid/quality-of-care/downloads/pcr-ta-resource.pdf
# Both As of May 28, 2021
module ClaimsReporting::Calculators
  class PcrRiskAdjustment
    extend Memoist

    # This class needs some support files to work. Helper method for places
    # where we want to test if it has what it nees
    def self.available?
      new
      true
    rescue StandardError
      false
    end

    # Note: This will raise if we are unable to load the XLSX files containing risk lookup data.
    def initialize
      # These must be downloaded separately.
      @shared_xlsx = Rails.root.join('config/claims_reporting/RAU Table - PCR Medicaid MY2020.xlsx')
      @pcr_xlsx = Rails.root.join('config/claims_reporting/PCR Risk Adjustment Tables MY2020.xlsx')

      raise <<~TXT unless File.exist?(@shared_xlsx) && File.exist?(@pcr_xlsx)
        Missing Risk Adjustment Tables

        To use the PcrRiskAdjustment calculator obtain:
          - RAU Table - PCR Medicaid MY2020.xlsx
          - PCR Risk Adjustment Tables MY2020.xlsx
        from the link below and place them in config/claims_reporting/

        http://store.ncqa.org/index.php/catalog/product/view/id/3761/s/hedis-my-2020-risk-adjustment-tables/
      TXT
    end

    # https://www.cms.gov/files/document/2021-qrs-measure-technical-specifications.pdf
    # "Risk Adjustment Comorbidity Category Determination"

    # Lookup HCC comorbidity categories based on DX codes
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
      # > Table CC—Comorbid [CC-Mapping in QRS2021]. If the code appears more than once in Table CC—Comorbid,
      # > it is assigned to multiple CCs.
      # >
      # > Exclude all diagnoses that cannot be assigned to a comorbid CC category.
      # > All digits must match exactly when mapping diagnosis codes to the comorbid CCs.
      cc_codes = dx_codes.flat_map { |dx| cc_mapping[dx] }.compact.uniq

      # > For members with no qualifying diagnoses from face-to-face encounters,
      # > skip to the Risk Adjustment Weighting section.
      return [] unless cc_codes.any?

      cc_to_hcc cc_codes
    end

    # Build a Hash of various calculated components based on attributes
    # of the Index Health Stay.
    def process_ihs(
      age:, # Integer age
      gender:, # Biological Sex: 'Male' or 'Female' (also accepts 'm' or 'f' or similar variants)
      observation_stay:, # true if the IHS was an 'Observation Stay'
      had_surgery:, # true if the patient had surgery during the stay
      discharge_dx_code:, # the primary discharge diagnosis on the IHS
      comorb_dx_codes: # all diagnoses for encounters during the classification period excluding the primary discharge diagnosis on the IHS
    )
      # For each IHS, use the following steps to identify risk adjustment weights based on presence of surgeries, discharge condition, comorbidity, age and gender.

      # 1. For each IHS discharge that is an observation stay, link the observation stay IHS weight.
      observation_weight = lookup_observation_stay_weight observation_stay

      # 2. For each IHS with a surgery, link the surgery weight.
      surg_weight = lookup_surgery_weight had_surgery

      # 3. For each IHS with a discharge CC Category, link the primary discharge weights.
      discharge_cc_codes = cc_mapping[discharge_dx_code] || [] # exclude dx note included
      discharge_weights = discharge_cc_codes.map do |discharge_cc|
        lookup_dcc_weight discharge_cc
      end

      # 4. For each IHS with a comorbidity HCC Category, link the weights.
      hcc_codes = calculate_hcc_codes(comorb_dx_codes)
      hcc_weights = hcc_codes.map do |hcc_code|
        lookup_hcc_weight hcc_code
      end

      # 5. Link the age and gender weights for each IHS.
      age_gender_weight = lookup_age_gender_weight(age, gender)

      # 6. Sum all weights associated with the IHS (i.e., observation
      # stay, presence of surgery, primary discharge diagnosis,
      # comorbidities, age and gender) and use the formula below to
      # calculate th𝑒𝑒e Estimated Readmission Risk for each IHS.
      sum_of_weights = ([
        observation_weight,
        surg_weight,
        age_gender_weight,
      ] + discharge_weights + hcc_weights).compact.sum

      # Estimated Readmission Risk = [exp (sum of weights for IHS)] / [ 1 + exp (sum of weights for IHS)]
      x = Math.exp(sum_of_weights)
      expected_readmit_rate = x / (1 + x)

      # 7. Calculate the Count of Expected Readmissions. The Count of Expected Readmissions
      # is the sum of the Estimated Readmission Risk calculated in step 6 for each IHS.
      # This gets done when summing patients/members

      # 8. Use the formula below and the Expected Readmissions Rate calculated in step 6 to
      # calculate the variance for each IHS.
      variance = expected_readmit_rate * (1 - expected_readmit_rate)

      {
        age: age,
        gender: gender,
        age_gender_weight: age_gender_weight,
        observation_stay: observation_stay,
        had_surgery: had_surgery,
        surg_weight: surg_weight,
        discharge_dx_code: discharge_dx_code,
        discharge_cc_codes: discharge_cc_codes,
        discharge_weights: discharge_weights,
        comorb_dx_codes: comorb_dx_codes,
        hcc_codes: hcc_codes,
        hcc_weights: hcc_weights,
        sum_of_weights: sum_of_weights,
        expected_readmit_rate: expected_readmit_rate,
        variance: variance,
      }
    end

    def cc_to_hcc(cc_codes, include_combos: true)
      # > Step 3 Determine HCCs for each comorbid CC identified. Refer to Table HCC—Rank.
      hcc_rows = []
      # > For each encounter’s comorbid CC list, match the comorbid CC code to the comorbid CC code
      # > in the table, and assign: The ranking group, The rank, The HCC.
      # > Note: One comorbid CC can map to multiple HCCs; each HCC can have one or more comorbid CCs.
      cc_codes.each do |cc_code|
        cc_rows = table_hcc_rank[cc_code]
        if cc_rows
          hcc_rows += cc_rows
        else
          # > For comorbid CCs that do not match to Table HCC—Rank, use the comorbid CC as the HCC
          # > and assign a rank of 1.
          hcc_rows << {
            ranking_group: 'Unmatched CC',
            cc: cc_code,
            hcc: "H#{cc_code}",
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
      hcc_codes = ranking_groups.values.map do |group_rows|
        group_rows.min_by { |r| r[:rank] }[:hcc]
      end.uniq

      # QRS 2021
      # > Step 5: Identify combination HCCs listed in Table HCC—Comb.
      hcc_codes += lookup_hcc_combo_codes(hcc_codes) if include_combos

      hcc_codes
    end

    def lookup_surgery_weight(had_surgery)
      return nil unless had_surgery

      pcr_rd_adjustments['Util|Surg|Standard - 18-64|Logistic']
    end

    def lookup_observation_stay_weight(observation_stay)
      return nil unless observation_stay

      pcr_rd_adjustments['Util|Obs|Standard - 18-64|Logistic']
    end

    def lookup_dcc_weight(cc_code)
      return nil unless cc_code.present?

      pcr_rd_adjustments["DCC|#{cc_code}|Standard - 18-64|Logistic"]
    end

    def lookup_hcc_weight(hcc_code)
      return nil unless hcc_code.present?

      pcr_rd_adjustments["HCC|#{hcc_code}|Standard - 18-64|Logistic"]
    end

    def lookup_age_gender_weight(age, gender)
      # We only need data on 12 to 64 year olds
      age_bucket = case age
      when 18..44 then '18-44'
      when 45..54 then '45-54'
      when 55..64 then '55-64'
      end

      gender_bucket = case gender
      when /^M/i then 'M'
      when /^F/i then 'F'
      end

      return unless age_bucket.present? && gender_bucket.present?

      pcr_rd_adjustments["Demo|#{gender_bucket}_#{age_bucket}|Standard - 18-64|Logistic"]
    end

    private def shared_roo
      ::Roo::Excelx.new(@shared_xlsx)
    end
    memoize :shared_roo

    private def pcr_roo
      ::Roo::Excelx.new(@pcr_xlsx)
    end
    memoize :pcr_roo

    # A Hash mapping DX codes to an Array of CC
    # codes
    def cc_mapping
      shared_roo.sheet('Table CC-Mapping').parse(
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
    memoize :cc_mapping

    # Row from Table HCC-Rank with Symbol
    # keys, grouped into a Hash keyed on CC code
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

    # A Hash of Set => String pairs to
    # lookup HHC combination codes. We use a Hash of Set's
    # only to maintain uniqueness. Per 2021 spec
    # the full table needs to be scanned for nested
    # and overlapping sets
    def table_hcc_comb
      lookup = {}
      # There tends to be notes like 'N/A' in columns sometimes
      # we want to filter those out.
      re_hcc_code = /HCC-\d+/

      shared_roo.sheet('Table HCC-Comb').parse(
        clean: true,
        hcc1: 'Comorbid HCC 1',
        hcc2: 'Comorbid HCC 2',
        hcc3: 'Comorbid HCC 3',
        hcc_comb: 'HCC-Comb',
        hcc_comb_desc: 'HCC-Comb Description',
      ).each do |row|
        # input codes
        hccs = Set.new
        [:hcc1, :hcc2, :hcc3].each do |col|
          hccs << row[col] if re_hcc_code.match? row[col]
        end

        lookup[hccs] = row[:hcc_comb] if hccs.size >= 2 && re_hcc_code.match?(row[:hcc_comb])
      end
      lookup
    end
    memoize :table_hcc_comb

    def lookup_hcc_combo_codes(hccs)
      # > Identify combination HCCs listed in Table HCC—Comb.
      # > Some combinations suggest a greater amount of risk when observed
      # > together.  For example, when diabetes and CHF are present, an
      # > increased amount of risk is evident.  Additional HCCs are
      # > selected to a> ccount for these relationships.
      lookup_table = table_hcc_comb

      # > Compare each encounter’s list of unique HCCs to those in the HCC
      # > column in Table HCC—Comb and assign any additional HCC
      # > conditions.
      candidates = []
      lookup_table.keys.each do |hcc_set|
        # when we have a combination (more than on) that intersects
        candidates << hcc_set if (hcc_set & hccs.to_a).size > 1
      end

      # > If there are fully nested combinations, use only the
      # > more comprehensive pattern. For example, if the diabetes/CHF
      # > combination is nested in the diabetes/CHF/renal combination,
      # > only the diabetes/CHF/renal combination is counted. If there are
      # > overlapping combinations, use both sets of combinations. Based
      # > on the combinations, a member can have none, one or more of
      # > these added HCCs.
      candidates.each do |hcc_set|
        # the data we have present in 2021 does not have any nested sets as described above. Implement this when we do
        raise 'Implement handling for nesting of HCC combinations' if hcc_set.size > 2
      end

      candidates.map do |key|
        lookup_table[key]
      end
    end

    def pcr_rd_adjustments
      pcr_roo.sheet('Medicaid').parse(
        clean: true,
        type: 'Variable Type',
        name: 'Variable Name',
        desc: 'Variable Description',
        indicator: 'Reporting Indicator',
        model: 'Model',
        adjustor_id: 'Adjustor ID',
        weight: 'Weight',
      ).map do |row|
        [row[:adjustor_id], row[:weight]]
      end.to_h.compact
    end
    memoize :pcr_rd_adjustments

    # In prior years we had different tables/tabs for each weight lookup
    # def hcc_surg
    #   pcr_roo.sheet('HCC-Surg').parse(
    #     clean: true,
    #     procedure_code: 'Procedure Code',
    #   ).map do |row|
    #     row[:procedure_code]
    #   end.compact.to_set
    # end
    # memoize :hcc_surg

    # def pcr_md_dischcc_weights
    #   pcr_roo.sheet('PCR-MD-DischCC-Weight').parse(
    #     clean: true,
    #     category: 'PCR-CC Category (Risk Marker)',
    #     weight: 'PCR-CC Weight',
    #   ).map do |row|
    #     [row[:category], row[:weight]]
    #   end.to_h.compact
    # end
    # memoize :pcr_md_dischcc_weights

    # def pcr_md_comorbhcc_weights
    #   pcr_roo.sheet('PCR-MD-ComorbHCC-Weight').parse(
    #     clean: true,
    #     category: 'PCR-HCC Category (Risk Marker)',
    #     weight: 'PCR-HCC Weight',
    #   ).map do |row|
    #     [row[:category], row[:weight]]
    #   end.to_h.compact
    # end
    # memoize :pcr_md_comorbhcc_weights

    # def pcr_md_other_weights
    #   pcr_roo.sheet('PCR-MD-OtherWeights').parse(
    #     clean: true,
    #     category: 'Description',
    #     weight: 'PCR Weight',
    #   ).map do |row|
    #     [row[:category], row[:weight]]
    #   end.to_h.compact
    # end
    # memoize :pcr_md_other_weights
  end
end
