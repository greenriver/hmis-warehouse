require 'roo'
require 'faker'

namespace :youth do
  desc 'Import youth data (client specific)'
  task :import, [:file_path] => [:environment, 'log:info_to_stdout'] do |_task, args|
    file_path = args.file_path || 'tmp/youth.xlsx'
    puts "Importing #{file_path}"

    # Some notes:
    # After running you'll want to ensure users are in the correct agency
    # user_id =
    # GrdaWarehouse::YouthIntake::Entry.where(user_id: 1).update_all(user_id: user_id)
    # GrdaWarehouse::Youth::YouthReferral.where(user_id: 1).update_all(user_id: user_id)
    # GrdaWarehouse::Youth::YouthCaseManagement.where(user_id: 1).update_all(user_id: user_id)
    # GrdaWarehouse::Youth::DirectFinancialAssistance.where(user_id: 1).update_all(user_id: user_id)

    def headers
      {
        updated_at: 'Timestamp',
        email: 'Email Address',
        client_name: 'Name of Youth',
        # _blank: '',
        staff_name: 'Name of staff working with the youth',
        engagement_date: 'Date of Engagement (When did you see the youth)',
        activity: 'Are you entering in a youth for the first time?',
        youth_attended: 'Did this Youth attend a Case Management meeting for today\'s date of engagement?',
        youth_experiencing_homelessness_at_start: 'Was this Youth experiencing homelessness when they began Case Management?',
        case_management_housing_status: 'Youth Housing Status Check up',
        _update: 'Do you want to update other information about this youth? (Demographic information, financial assistance, etc?)',
        unaccompanied: 'Is this youth Unaccompanied? (An individual who is not in the physical custody or care of a  parent / legal guardian)',
        street_outreach_contact: 'Is this Youth a Street Outreach Contact',
        housing_status: 'Housing Status',
        other_agency_involvement: 'Is this youth involved with any other state Agencies?',
        owns_cell_phone: 'Does this youth own a cell phone?',
        secondary_education: 'Secondary Education',
        attending_college: 'Is this youth attending college?',
        health_insurance: 'Does this youth have health insurance?',
        requesting_financial_assistance: 'Is this youth asking for or receiving financial assistance from us at the time of entering this data?',
        client_dob: 'Youth Birthday',
        staff_believes_youth_under_24: 'Staff believes youth is 24 or under?',
        client_gender: 'Gender',
        client_lgbtq: 'Is the youth LGBTQ+ ?',
        client_race: 'Race (Check all that apply)',
        client_ethnicity: 'Ethnicity',
        client_primary_language: 'Primary Language',
        pregnant_or_parenting: 'Is this youth Pregnant or Parenting?',
        disabilities: 'Disabilities, check all that apply.',
        how_hear: 'How did this Youth hear about us?',
        financial_assistance_provided: 'Has this youth received any direct financial assistance?',
        financial_assistance_type_provided: 'What kinds of Financial Assistance has this youth received, select all that apply.',
        needs_shelter: 'Is this Youth in need of a shelter?',
        referred_to_shelter: 'Did we refer them to a shelter?',
        in_stable_housing: 'Is this youth currently in stable housing?',
        stable_housing_zipcode: '(If stably housed) What is the zipcode of the stable housing this youth is in?',
        referred_to: 'Please check all applicable referrals',
        youth_case_management: 'Do you have a case management meeting / intake meeting to log for today\'s date of engagement?',
        PersonalID: 'Unique ID',
      }
    end

    def race(race_string)
      {
        'AmIndAKNative' => 'American Indian or Alaska Native',
        'Asian' => 'Asian',
        'BlackAfAmerican' => 'Black or African American',
        'NativeHIOtherPacific' => 'Native Hawaiian or Other Pacific Islander',
        'White' => 'White / Caucasian',
      }.invert[race_string]
    end

    def ethnicity(ethnicity_string)
      {
        0 => 'Non-Hispanic / Non-Latino',
        1 => 'Hispanic / Latino',
        8 => 'Unknown',
        9 => 'Youth refused',
        99 => 'Data not collected',
      }.invert[ethnicity_string]
    end

    def gender(gender_string)
      {
        'Female' => 0,
        'Male' => 1,
        'Trans Male (MTF or Male to Female)' => 3,
        'Trans Female (MTF or Male to Female)' => 2,
        'Trans Male (FTM or Female to Male)' => 3,
        'Trans Female (FTM or Female to Male)' => 2,
        'Gender non-conforming (i.e. not exclusively male or female)' => 4,
        'Unknown' => 8,
        'Youth Refused' => 9,
        'Data not collected' => 99,
      }[gender_string]
    end

    def financial_assistances
      {
        'Move-in Costs' => 'Move-in costs',
        'Rent' => 'Rent',
        'Rent arrears' => 'Rent arrears',
        'Utilities' => 'Utilities',
        'Transportation-related Costs' => 'Transportation-related costs',
        'Traveling to gain housing/bus ticket' => 'Transportation-related costs',
        'Education-related costs' => 'Education-related costs',
        'Legal costs' => 'Legal costs',
        'Child care' => 'Child care',
        'Work-related costs' => 'Work-related costs',
        'Medical costs' => 'Medical costs',
        'Cell phone costs' => 'Cell phone costs',
        'Food/Groceries (including our drop in food pantries)' => 'Food / Groceries (including our drop-in food pantries)',
        'Motel Stay' => 'Hotel or Motel Stay',
        'Hotel Stay' => 'Hotel or Motel Stay',
        'Hotel Stay 1/25-1/27' => 'Hotel or Motel Stay',
        'Motel stay' => 'Hotel or Motel Stay',
        'Hotel' => 'Hotel or Motel Stay',
        'Cell Phone Costs' => 'Cell phone costs',
        'Provided a Trac Phone' => 'Cell phone costs',
        'Emergency Shelter Night Owl Stay' => 'Emergency Shelter Night Owl Stay',
        'Emergency Shelter' => 'Emergency Shelter Hotel',
      }
    end

    def case_management_housing_situations
      {
        'This youth is currently in stable housing' => 'This youth is currently in stable housing',
        'This youth is at risk of homelessness (within the next 14 days)' => 'This youth is currently in stable housing',
        'This youth is at risk of homelessness (within the next four months)' => 'This youth is currently in stable housing',
        'Allowed to come back home today' => 'This youth is currently in stable housing',
        'This youth is not currently in stable housing' => 'This youth is not currently in stable housing',
        'Wells Street Shelter' => 'This youth is not currently in stable housing',
        'youth is exiting housing 10/31/19 and is 25' => 'This youth is not currently in stable housing',
        'staying at The Warming Center Greenfield, MA' => 'This youth is not currently in stable housing',
        'Kicked out today' => 'This youth is not currently in stable housing',
        'Northern Hope until 11/25/19' => 'This youth is not currently in stable housing',
        'Couch surfing' => 'This youth is not currently in stable housing',
        'DMH Respite Bed  ' => 'This youth is not currently in stable housing',
        'In Shelter' => 'This youth is not currently in stable housing',
        'Unknown' => 'Unknown',
        'Other' => 'Other:',
      }
    end

    def available_referrals
      {
        'Referred for housing supports (Include housing supports provided with non-EOHHS funding including housing search, subsidies, RAFT, FUP, direct financial support, etc.)' => 'Referred for housing supports (include housing supports provided with no-EOHHS funding including housing search)',
        'Referred for health services' => 'Referred for health services',
        'Referred for mental health services' => 'Referred for mental health services',
        'Referred for employment & job training services' => 'Referred for employment & job training services',
        'Referred to Benefits providers (SNAP, SSI, WIC etc)' => 'Referred to Benefits providers (SNAP, SSI, WIC, etc.)',
        'Referred to other state agencies (DMH, DDS, etc)' => 'Referred to other state agencies (DMH, DDS, etc.)',
        'Referred for substance use services' => 'Referred for substance use services',
        'Referred to other services / activities not listed above' => 'Referred to other services / activities not listed above',
        'Referred for lifeskills / financial literacy services' => 'Referred for lifeskills / financial literacy services',
        'Referred for education services' => 'Referred for education services',
        'Referred for parenting services' => 'Referred for parenting services',
        'Referred for domestic violence-related services' => 'Referred for domestic violence-related services',
        'Referred to health insurance providers' => 'Referred to health insurance providers',
        'Referred for legal services' => 'Referred for legal services',
        'Referred to cultural / recreational activities' => 'Referred to cultural / recreational activities',
      }
    end

    def available_disabilities
      {
        'Mental / Emotional Disability' => 'Mental / Emotional disability',
        'Medical / Physical Disability' => 'Medical / Physical disability',
        'Developmental Disability' => 'Developmental disability',
        'No Disabilities' => 'No disabilities',
        'Unknown' => 'Unknown',
      }
    end

    def housing_situations
      {
        'Unknown' => 'Unknown',
        'Stably housed' => 'Stably housed',
        'Experiencing Homelessness: Couch Surfing' => 'Experiencing homelessness: couch surfing',
        'Unstably housed' => 'Unstably housed',
        'Experiencing Homelessness: Street' => 'Experiencing homelessness: street',
        'Experiencing Homelessness: In shelter' => 'Experiencing homelessness: in shelter',
        'At risk of homelessness' => 'At risk of homelessness',
        'This youth is currently in stable housing' => 'Stably housed',
        'This youth is at risk of homelessness (within the next 14 days)' => 'At risk of homelessness',
        'This youth is at risk of homelessness (within the next four months)' => 'At risk of homelessness',
        'Allowed to come back home today' => 'Stably housed',
        'This youth is not currently in stable housing' => 'Experiencing homelessness: street',
        'Wells Street Shelter' => 'Experiencing homelessness: in shelter',
        'youth is exiting housing 10/31/19 and is 25' => 'Experiencing homelessness: in shelter',
        'staying at The Warming Center Greenfield, MA' => 'Experiencing homelessness: in shelter',
        'Kicked out today' => 'Experiencing homelessness: street',
        'Northern Hope until 11/25/19' => 'Experiencing homelessness: in shelter',
        'Couch surfing' => 'Experiencing homelessness: couch surfing',
        'DMH Respite Bed  ' => 'Experiencing homelessness: in shelter',
        'In Shelter' => 'Experiencing homelessness: in shelter',
      }
    end

    prior_import_date = '2020-06-20'.to_date

    data_source = GrdaWarehouse::DataSource.authoritative.youth.first_or_create do |ds|
      ds.name = 'DIAL/SELF Youth'
      ds.short_name = 'Youth'
    end
    # GrdaWarehouse::Youth::YouthReferral.where(imported: true).destroy_all
    # GrdaWarehouse::Youth::YouthCaseManagement.where(imported: true).destroy_all
    # GrdaWarehouse::Youth::DirectFinancialAssistance.where(imported: true).destroy_all
    # GrdaWarehouse::YouthIntake::Base.where(imported: true).destroy_all
    # Faker leaves a mess behind, so we'll clean this up for development runs
    GrdaWarehouse::Hud::Client.where(data_source_id: data_source.id).destroy_all if Rails.env.development?

    xlsx = Roo::Spreadsheet.open(file_path)
    sheet = xlsx.sheet(0)

    client_names = {}
    staff_names = {}
    staff_email = {}
    clients = {}
    intakes_created = 0
    intakes_failed = 0
    # Process
    # -1 destroy any previously imported intakes, referrals, manag
    # 0. make data source DIAL/SELF Youth
    # 0.5 sort by updated_at
    # 1. Loop through xlsx
    # 2. Pickup FirstName, LastName, DOB - find or create client in GrdaWarehouse::DataSource.authoritative.youth
    # 2.5 match existing, not destination clients for creating intakes
    # 3. Create one intake per client, potentially update if seen again
    # 4. Create one case management note per row with youth_case_management == Yes
    # 5. Create one referral per row with referrals == Yes
    # 6. Create one direct financial assistance per row with financial_assistance_provided == Yes

    rows = sheet.parse(headers)
    rows.each do |row|
      # Basic anonymization
      if Rails.env.development?
        client_names[row[:PersonalID]] ||= Faker::Name.name
        staff_names[row[:PersonalID]] ||= Faker::Name.name
        staff_email[row[:email]] ||= Faker::Internet.email
        row[:client_name] = client_names[row[:PersonalID]]
        row[:staff_name] = staff_names[row[:PersonalID]]
        row[:email] = staff_email[row[:email]]
      end
      first_name, last_name = row[:client_name].strip.split(' ', 2)
      user_id = User.find_by(email: row[:email])&.id || User.setup_system_user.id
      clients[row[:PersonalID]] ||= {
        client: {
          FirstName: first_name,
          LastName: last_name,
          DOB: row[:client_dob],
          PersonalID: row[:PersonalID],
          DateCreated: Time.current,
          DateUpdated: Time.current,
        },
        intakes: [],
        referrals: [],
        financials: [],
        case_managements: [],
      }

      if row[:activity] == 'Update Case Management meetings, engagement and housing status' && row[:case_management_housing_status]&.strip.present?
        clean_case_management_status = case_management_housing_situations[row[:case_management_housing_status]]
        raise "Missing Case Management status #{row[:case_management_housing_status].inspect}" unless clean_case_management_status.present?

        clients[row[:PersonalID]][:case_managements] << {
          engaged_on: row[:engagement_date],
          housing_status: row[:case_management_housing_status],
          activity: row[:activity],
          user_id: user_id,
          imported: true,
        }
      end

      if row[:referred_to].present?
        # this is ugly, but some of the referrals have commas in them
        referrals = row[:referred_to].split(', Re')
        referrals = referrals.map { |r| r = if r&.starts_with?('Re') then r else "Re#{r}" end }
        referrals.compact.each do |referred_to|
          clean_referred_to = available_referrals[referred_to]
          raise "Missing referral type: #{referred_to.inspect}" unless clean_referred_to.present?

          clients[row[:PersonalID]][:referrals] << {
            referred_on: row[:engagement_date],
            referred_to: clean_referred_to,
            user_id: user_id,
            imported: true,
          }
        end
      end

      if row[:financial_assistance_type_provided].present?
        types = row[:financial_assistance_type_provided].split(', ')
        types.each do |type|
          clean_type = financial_assistances[type]
          raise "Missing financial type: #{type.inspect}" unless clean_type.present?

          clients[row[:PersonalID]][:financials] << {
            provided_on: row[:engagement_date],
            type_provided: clean_type,
            user_id: user_id,
            imported: true,
          }
        end
      end

      races = row[:client_race]&.split(',')&.map { |r| race(r&.strip) }
      ethnicity = ethnicity(row[:client_ethnicity]&.strip)
      h_status = housing_situations[row[:housing_status]] || housing_situations[row[:case_management_housing_status]]
      disabilities = row[:disabilities]&.split(', ')&.map { |d| available_disabilities[d] }&.compact

      intake = {
        user_id: user_id,
        staff_email: row[:email],
        staff_name: row[:staff_name],
        engagement_date: row[:engagement_date],
        housing_status: h_status,
        client_race: races,
        client_ethnicity: ethnicity,
        client_primary_language: row[:client_primary_language],
        client_dob: row[:client_dob],
        client_gender: gender(row[:client_gender]),
        disabilities: disabilities,
        how_hear: row[:how_hear],
        stable_housing_zipcode: row[:stable_housing_zipcode],
        imported: true,
      }
      intake[:youth_experiencing_homelessness_at_start] = row[:youth_experiencing_homelessness_at_start] if row[:youth_experiencing_homelessness_at_start].present? && intake[:youth_experiencing_homelessness_at_start].blank?
      intake[:unaccompanied] = row[:unaccompanied] if row[:unaccompanied].present? && intake[:unaccompanied].blank?
      intake[:street_outreach_contact] = row[:street_outreach_contact] if row[:street_outreach_contact].present? && intake[:street_outreach_contact].blank?
      intake[:other_agency_involvements] = [row[:other_agency_involvement]] if row[:other_agency_involvement].present? && intake[:other_agency_involvements].blank?
      intake[:owns_cell_phone] = row[:owns_cell_phone] if row[:owns_cell_phone].present? && intake[:owns_cell_phone].blank?
      intake[:secondary_education] = row[:secondary_education] if row[:secondary_education].present? && intake[:secondary_education].blank?
      intake[:attending_college] = row[:attending_college] if row[:attending_college].present? && intake[:attending_college].blank?
      intake[:health_insurance] = row[:health_insurance] if row[:health_insurance].present? && intake[:health_insurance].blank?
      intake[:client_lgbtq] = row[:client_lgbtq] if row[:client_lgbtq].present? && intake[:client_lgbtq].blank?
      intake[:pregnant_or_parenting] = row[:pregnant_or_parenting] if row[:pregnant_or_parenting].present? && intake[:pregnant_or_parenting].blank?
      intake[:needs_shelter] = row[:needs_shelter] if row[:needs_shelter].present? && intake[:needs_shelter].blank?
      intake[:referred_to_shelter] = row[:referred_to_shelter] if row[:referred_to_shelter].present? && intake[:referred_to_shelter].blank?
      intake[:in_stable_housing] = row[:in_stable_housing] if row[:in_stable_housing].present? && intake[:in_stable_housing].blank?
      intake[:staff_believes_youth_under_24] = row[:staff_believes_youth_under_24] if row[:staff_believes_youth_under_24].present? && intake[:staff_believes_youth_under_24].blank?
      intake[:requesting_financial_assistance] = row[:requesting_financial_assistance] if row[:requesting_financial_assistance].present? && intake[:requesting_financial_assistance].blank?

      clients[row[:PersonalID]][:intakes] << intake
    end

    GrdaWarehouse::Hud::Client.transaction do
      clients.each do |_personal_id, data|
        client = data[:client]
        client[:data_source_id] = data_source.id
        source_client = GrdaWarehouse::Hud::Client.where(
          data_source_id: client[:data_source_id],
          PersonalID: client[:PersonalID],
        ).first_or_initialize
        source_client.update(client.except(:source_client))

        client[:source_client] = source_client
      end

      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!

      # NOTE: this process assumes intakes are in chronological order for each client
      clients.each do |_personal_id, data|
        destination_client = data[:client][:source_client].destination_client
        destination_client_id = destination_client.id
        # Make a single intake with the most recent data
        intake = {}
        data[:intakes].each_with_index do |int, i|
          int.each do |k, v|
            # include all answers for the first row
            # include any answers where we have data
            intake[k] = v if v.present? || i == 0
          end
        end
        # Ensure we have required fields
        intake[:youth_experiencing_homelessness_at_start] ||= 'No'
        intake[:unaccompanied] ||= 'No'
        intake[:street_outreach_contact] ||= 'No'
        intake[:other_agency_involvements] ||= ['No']
        intake[:owns_cell_phone] ||= 'No'
        intake[:secondary_education] ||= 'No'
        intake[:attending_college] ||= 'No'
        intake[:health_insurance] ||= 'No'
        intake[:client_lgbtq] ||= 'No'
        intake[:pregnant_or_parenting] ||= 'No'
        intake[:needs_shelter] ||= 'No'
        intake[:referred_to_shelter] ||= 'No'
        intake[:in_stable_housing] ||= 'No'
        intake[:staff_believes_youth_under_24] ||= 'No'
        intake[:requesting_financial_assistance] ||= 'No'
        intake[:client_ethnicity] ||= 99
        intake[:client_gender] ||= 99
        intake[:client_primary_language] ||= 'Unknown'
        intake[:disabilities] ||= []
        intake[:client_race] ||= []
        intake[:first_name] = data[:client][:FirstName]
        intake[:last_name] = data[:client][:LastName]
        intake[:ssn] = data[:client][:SSN]

        # The following fields are required at the DB level
        intake[:housing_status] ||= intake[:case_management_housing_status] || ''

        # But use the first engagement_date
        first_intake = data[:intakes].first
        next unless first_intake.present?

        intake[:engagement_date] = first_intake.try(:[], :engagement_date)
        intake[:client_id] = destination_client_id

        entry = GrdaWarehouse::YouthIntake::Entry.new(intake)
        if entry.valid?
          intakes_created += 1
        else
          intakes_failed += 1
          # puts "Invalid record #{intake.inspect} #{entry.errors.full_messages.inspect}"
        end
        # Identify if we have an existing Intake based on the date and client
        existing_intake = destination_client.youth_intakes.where(engagement_date: intake[:engagement_date]).first
        # if we don’t, we’ll simply add the new intake
        if existing_intake.blank?
          entry.save(validate: false)
        # if we do, and it unchanged since the prior import, replace it with the incoming data
        elsif existing_intake.imported?
          if existing_intake.created_at == existing_intake.updated_at && existing_intake.created_at.to_date <= prior_import_date
            existing_intake.destroy
            entry.save(validate: false)
          end
        end

        data[:case_managements].each do |ref|
          ref[:client_id] = destination_client_id
          existing_note = destination_client.case_managements.where(imported: true, engaged_on: ref[:engaged_on]).first
          if existing_note.blank?
            GrdaWarehouse::Youth::YouthCaseManagement.create!(ref)
          elsif existing_note.created_at == existing_note.updated_at && existing_note.created_at.to_date <= prior_import_date
            existing_note.destroy
            GrdaWarehouse::Youth::YouthCaseManagement.create!(ref)
          end
        end

        data[:referrals].each do |ref|
          ref[:client_id] = destination_client_id
          GrdaWarehouse::Youth::YouthReferral.create!(ref) unless destination_client.youth_referrals.where(
            referred_on: ref[:referred_on],
            referred_to: ref[:referred_to],
          ).exists?
        end

        data[:financials].each do |ref|
          ref[:client_id] = destination_client_id
          GrdaWarehouse::Youth::DirectFinancialAssistance.create!(ref) unless destination_client.direct_financial_assistances.where(
            provided_on: ref[:provided_on],
            type_provided: ref[:type_provided],
          ).exists?
        end
      end
    end # end transaction

    puts "Valid: #{intakes_created} intakes; Invalid: #{intakes_failed} intakes"
    puts "Note, that you'll probably need to update the user_id on all imported items to match an existing user"
  end
end
