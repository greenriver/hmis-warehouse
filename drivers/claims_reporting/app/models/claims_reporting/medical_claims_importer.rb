# Class to handle upsert style inserts from a CSV (and potentially other flat file formats
# into ClaimsReporting::MedicalClaims.
require 'csv'

module ClaimsReporting
  class MedicalClaimsImporter
    def self.reimport_all(path)
      raise "#{path} not found or empty" unless File.size?(path)

      i = new
      File.open(path) do |f|
        i.import(f, filename: path, replace_all: true)
      end
    end

    CSV_SCHEMA = <<~CSV.freeze
      ID,Field name,Description,Length,Data type,PRIVACY: Encounter pricing
      1,member_id,Member's Medicaid identification number ,50,string,-
      2,claim_number,Claim number,30,string,-
      3,line_number,Claim detail line number,10,string,-
      4,cp_pidsl,CP entity ID. PIDSL is a combination of provider ID and service location,50,string,-
      5,cp_name,CP name,255,string,-
      6,aco_pidsl,ACO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
      7,aco_name,ACO name,255,string,-
      8,pcc_pidsl,PCC ID. PIDSL is a combination of provider ID and service location,50,string,-
      9,pcc_name,PCC name,255,string,-
      10,pcc_npi,PCC national provider identifier (NPI),50,string,-
      11,pcc_taxid,PCC tax identification number (TIN),50,string,-
      12,mco_pidsl,MCO entity ID. PIDSL is a combination of provider ID and service location,50,string,-
      13,mco_name,MCO name,50,string,-
      14,source,"Payor of the claim: MCO or MMIS (MH). Note that some claims will be paid by MMIS (MH) even if a member is enrolled in an MCO or Model A ACO (e.g., wrap services). ",50,string,-
      15,claim_type,Claim type,255,string,-
      16,member_dob,Member date of birth,30,date (YYYY-MM-DD),-
      17,patient_status,Indicates the status of the member as of the ending service date of the period covered.,255,string,-
      18,service_start_date,Service start date,30,date (YYYY-MM-DD),-
      19,service_end_date,Service end date,30,date (YYYY-MM-DD),-
      20,admit_date,Admit date,30,date (YYYY-MM-DD),-
      21,discharge_date,Discharge date,30,date (YYYY-MM-DD),-
      22,type_of_bill,"The Type of Bill (TOB) is a three digit entry. The first digit is the type of facility, the second digit is the bill classification, and the third digit is frequency.",255,string,-
      23,admit_source,Code identifying the source of admission for inpatient  claims,255,string,-
      24,admit_type,Code which indicates the priority of the admission of a member for inpatient services ,255,string,-
      25,frequency_code,Third character of TYPE_OF_BILL. This field specifies the bill frequency.,255,string,-
      26,paid_date,Paid date,30,date (YYYY-MM-DD),-
      27,billed_amount,Amount requested by provider for services rendered. ,30,"decimal(19,4)",Redacted
      28,allowed_amount,Amount for claim allowed by payor ,30,"decimal(19,4)",Redacted
      29,paid_amount,Amount sent to a provider for payment for services rendered to a member,30,"decimal(19,4)",Redacted
      30,admit_diagnosis,Admitting diagnosis on the claim,50,string,-
      31,dx_1,First-listed Diagnosis. ,50,string,-
      32,dx_2,Diagnosis 2,50,string,-
      33,dx_3,Diagnosis 3,50,string,-
      34,dx_4,Diagnosis 4,50,string,-
      35,dx_5,Diagnosis 5,50,string,-
      36,dx_6,Diagnosis 6,50,string,-
      37,dx_7,Diagnosis 7,50,string,-
      38,dx_8,Diagnosis 8,50,string,-
      39,dx_9,Diagnosis 9,50,string,-
      40,dx_10,Diagnosis 10,50,string,-
      41,dx_11,Diagnosis 11,50,string,-
      42,dx_12,Diagnosis 12,50,string,-
      43,dx_13,Diagnosis 13,50,string,-
      44,dx_14,Diagnosis 14,50,string,-
      45,dx_15,Diagnosis 15,50,string,-
      46,dx_16,Diagnosis 16,50,string,-
      47,dx_17,Diagnosis 17,50,string,-
      48,dx_18,Diagnosis 18,50,string,-
      49,dx_19,Diagnosis 19,50,string,-
      50,dx_20,Diagnosis 20,50,string,-
      51,dx_21,Diagnosis 21,50,string,-
      52,dx_22,Diagnosis 22,50,string,-
      53,dx_23,Diagnosis 23,50,string,-
      54,dx_24,Diagnosis 24,50,string,-
      55,dx_25,Diagnosis 25,50,string,-
      56,e_dx_1,External injury diagnosis 1,50,string,-
      57,e_dx_2,External injury diagnosis 2,50,string,-
      58,e_dx_3,External injury diagnosis 3,50,string,-
      59,e_dx_4,External injury diagnosis 4,50,string,-
      60,e_dx_5,External injury diagnosis 5,50,string,-
      61,e_dx_6,External injury diagnosis 6,50,string,-
      62,e_dx_7,External injury diagnosis 7,50,string,-
      63,e_dx_8,External injury diagnosis 8,50,string,-
      64,e_dx_9,External injury diagnosis 9,50,string,-
      65,e_dx_10,External injury diagnosis 10,50,string,-
      66,e_dx_11,External injury diagnosis 11,50,string,-
      67,e_dx_12,External injury diagnosis 12,50,string,-
      68,icd_version,ICD version type,50,string,-
      69,surgical_procedure_code_1,Surgical procedure code 1,50,string,-
      70,surgical_procedure_code_2,Surgical procedure code 2,50,string,-
      71,surgical_procedure_code_3,Surgical procedure code 3,50,string,-
      72,surgical_procedure_code_4,Surgical procedure code 4,50,string,-
      73,surgical_procedure_code_5,Surgical procedure code 5,50,string,-
      74,surgical_procedure_code_6,Surgical procedure code 6,50,string,-
      75,revenue_code,Revenue code,50,string,-
      76,place_of_service_code,Place of service code,50,string,-
      77,procedure_code,Procedure code,50,string,-
      78,procedure_modifier_1,Procedure modifier 1,50,string,-
      79,procedure_modifier_2,Procedure modifier 2,50,string,-
      80,procedure_modifier_3,Procedure modifier 3,50,string,-
      81,procedure_modifier_4,Procedure modifier 4,50,string,-
      82,drg_code,Code identifying a DRG grouping.,50,string,-
      83,drg_version_code,Description of the DRG grouper.,50,string,-
      84,severity_of_illness,Severity of Illness (SOI) subclass at discharge. ,50,string,-
      85,service_provider_npi,Service provider national provider identifier,50,string,-
      86,id_provider_servicing,Service provider ID,50,string,-
      87,servicing_taxid,Service provider tax identification number (TIN),50,string,-
      88,servicing_provider_name,Service provider name,512,string,-
      89,servicing_provider_type,Type that a servicing provider is licensed for. ,255,string,-
      90,servicing_provider_taxonomy,Service provider taxonomy,255,string,-
      91,servicing_address,Service provider address line 1,512,string,-
      92,servicing_city,Service provider city,255,string,-
      93,servicing_state,Service provider state,255,string,-
      94,servicing_zip,Service provider zip,50,string,-
      95,billing_npi,Billing provider national provider identifier,50,string,-
      96,id_provider_billing,Billing provider ID,50,string,-
      97,billing_taxid,Billing provider  tax identification number TIN,50,string,-
      98,billing_provider_name,Billing provider name,512,string,-
      99,billing_provider_type,Type that a Billing provider is licensed for. ,50,string,-
      100,billing_provider_taxonomy,Billing provider taxonomy,50,string,-
      101,billing_address,Billing provider address line 1,512,string,-
      102,billing_city,Billing provider city,255,string,-
      103,billing_state,Billing provider state,255,string,-
      104,billing_zip,Billing provider zip,50,string,-
      105,claim_status,"Claim status (P - paid, D - denied)",255,string,-
      106,disbursement_code,Disbursement code: represents which state agency is responsible for the claim. 0 is MassHealth paid.,255,string,-
      107,enrolled_flag,Y/N flag depending on if member is current with your entity,50,string,-
      108,referral_circle_ind,Flag (Y /N) used to indicate whether a claim was paid or denied by a service provider who is part of the referral circle,50,string,-
      109,mbhp_flag,Indicator for MBHP claims,50,string,-
      110,present_on_admission_1,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      111,present_on_admission_2,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      112,present_on_admission_3,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      113,present_on_admission_4,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      114,present_on_admission_5,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      115,present_on_admission_6,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      116,present_on_admission_7,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      117,present_on_admission_8,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      118,present_on_admission_9,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      119,present_on_admission_10,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      120,present_on_admission_11,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      121,present_on_admission_12,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      122,present_on_admission_13,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      123,present_on_admission_14,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      124,present_on_admission_15,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      125,present_on_admission_16,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      126,present_on_admission_17,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      127,present_on_admission_18,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      128,present_on_admission_19,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      129,present_on_admission_20,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      130,present_on_admission_21,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      131,present_on_admission_22,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      132,present_on_admission_23,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      133,present_on_admission_24,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      134,present_on_admission_25,Diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      135,e_dx_present_on_admission_1,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      136,e_dx_present_on_admission_2,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      137,e_dx_present_on_admission_3,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      138,e_dx_present_on_admission_4,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      139,e_dx_present_on_admission_5,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      140,e_dx_present_on_admission_6,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      141,e_dx_present_on_admission_7,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      142,e_dx_present_on_admission_8,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      143,e_dx_present_on_admission_9,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      144,e_dx_present_on_admission_10,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      145,e_dx_present_on_admission_11,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      146,e_dx_present_on_admission_12,External injury diagnosis code indicates present on admission. Each relates to diagnosis code of same number. ,50,string,-
      147,quantity,Quantity billed,30,"decimal(12,4)",-
      148,price_method,Indicates the pricing method used for payment of the claim,50,string,-
    CSV

    # Expects an IO and a String filename for the logs.
    #
    # Returns the number of rows processed.
    def import(io, filename:, replace_all:) # rubocop:disable Naming/MethodParameterName
      # TODO: Support partial updates by reading rows into tmp table with with_temp_table
      # and then upserting in the final table
      data = io.each_line
      table_name = MedicalClaim.quoted_table_name
      MedicalClaim.transaction do
        conn.truncate(MedicalClaim.table_name) if replace_all
        col_list = csv_cols.join(',')
        log_timing "Loading #{filename} in #{table_name} cols:#{col_list}" do
          copy_sql = <<~SQL.strip
            COPY #{table_name} (#{col_list})
            FROM STDIN
            WITH (FORMAT csv,HEADER,QUOTE '"',DELIMITER '|',FORCE_NULL(#{force_null_cols.join(',')}))
          SQL
          logger.debug { copy_sql }
          pg_conn = conn.raw_connection
          pg_conn.copy_data copy_sql do
            data.each do |line|
              pg_conn.put_copy_data(line)
            end
          end
        end
      end
    end

    def csv_schema
      @csv_schema ||= CSV.parse CSV_SCHEMA, headers: true, converters: lambda { |value, field_info|
        if field_info.header == 'PRIVACY: Encounter pricing' && value == '-'
          nil
        else
          value
        end
      }
    end

    def csv_cols
      csv_schema.map { |r| r['Field name'] }
    end

    def force_null_cols
      csv_schema.reject { |r| r['Data type'] == 'string' }.map { |r| r['Field name'] }
    end

    def generate_table_definition
      csv_schema.each do |row|
        db_type = row['Data type']
        db_type = 'date' if db_type == 'date (YYYY-MM-DD)'
        puts "t.column '#{row['Field name']}', '#{db_type}', limit: #{db_type == 'string' ? row['Length'] : 'nil'}"
      end
    end

    private def with_temp_table
      tmp_table_name = "mr_#{SecureRandom.hex}"
      log_timing 'Create temp table' do
        conn.create_table(tmp_table_name, id: false, temporary: true) do |t|
          csv_schema.each do |row|
            db_type = row['Data type']
            db_type = 'date' if db_type == 'date (YYYY-MM-DD)'
            t.column(
              row['Field name'],
              db_type,
              limit: (row['Length'] if db_type == 'string'),
              # comment: row['Description'],
            )
          end
        end
      end
      yield tmp_table_name
    ensure
      conn.drop_table(tmp_table_name, if_exists: true)
    end

    private def log_timing(str)
      logger.info { "#{self.class}: #{str} started" }
      res = nil
      bm = Benchmark.measure do
        res = yield
      end
      msg = "#{self.class}: #{str} completed in #{bm.to_s.strip}"
      puts msg
      logger.info msg
      res
    end

    private def conn
      HealthBase.connection
    end

    private def logger
      HealthBase.logger
    end
  end
end
