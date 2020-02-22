require 'roo'
require 'faker'

namespace :youth do
  desc "Import youth data (client specific)"
  task :import, [:file_path] => [:environment, "log:info_to_stdout"] do |task, args|
    file_path = args.file_path || 'var/youth.xlsx'
    puts "Importing #{file_path}"

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
        referrals: 'Please check all applicable referrals',
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

    data_source = GrdaWarehouse::DataSource.authoritative.youth.first_or_create do |ds|
      ds.name = 'DIAL/SELF Youth'
      ds.short_name = 'Youth'
    end
    GrdaWarehouse::Youth::YouthReferral.where(imported: true).destroy_all
    GrdaWarehouse::Youth::YouthCaseManagement.where(imported: true).destroy_all
    GrdaWarehouse::Youth::DirectFinancialAssistance.where(imported: true).destroy_all
    GrdaWarehouse::YouthIntake::Base.where(imported: true).destroy_all
    # Faker leaves a mess behind, so we'll clean this up for development runs
    if Rails.env.development?
      GrdaWarehouse::Hud::Client.where(data_source_id: data_source.id).destroy_all
    end

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
    sheet.each(headers) do |row|
      next if row[:updated_at] == 'Timestamp'
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
      if row[:youth_case_management] == 'Yes' || row[:case_management_housing_status].present?
        clients[row[:PersonalID]][:case_managements] << {
          engaged_on: row[:engagement_date],
          housing_status: row[:case_management_housing_status],
          activity: row[:activity],
          user_id: user_id,
          imported: true,
        }
      end
      if row[:referrals] == 'Yes' || row[:referred_to_shelter].present?
        clients[row[:PersonalID]][:referrals] << {
          referred_on: row[:engagement_date],
          referred_to: row[:referred_to_shelter],
          user_id: user_id,
          imported: true,
        }
      end
      if row[:financial_assistance_provided] == 'Yes' || row[:financial_assistance_type_provided].present?
        clients[row[:PersonalID]][:financials] << {
          provided_on: row[:engagement_date],
          type_provided: row[:financial_assistance_type_provided],
          user_id: user_id,
          imported: true,
        }
      end
      races = row[:client_race]&.split(',')&.map{|r| race(r&.strip)}
      ethnicity = ethnicity(row[:client_ethnicity]&.strip)
      intake = {
        user_id: user_id,
        staff_email: row[:email],
        staff_name: row[:staff_name],
        engagement_date: row[:engagement_date],
        housing_status: row[:housing_status],
        client_race: races,
        client_ethnicity: ethnicity,
        client_primary_language: row[:client_primary_language],
        client_dob: row[:client_dob],
        client_gender: gender(row[:client_gender]),
        disabilities: row[:disabilities]&.split(', '),
        how_hear: row[:how_hear],
        stable_housing_zipcode: row[:stable_housing_zipcode],
        imported: true,
      }
      intake[:youth_experiencing_homelessness_at_start] = row[:youth_experiencing_homelessness_at_start] if row[:youth_experiencing_homelessness_at_start].present?
      intake[:unaccompanied] = row[:unaccompanied] if row[:unaccompanied].present?
      intake[:street_outreach_contact] = row[:street_outreach_contact] if row[:street_outreach_contact].present?
      intake[:other_agency_involvement] = row[:other_agency_involvement] if row[:other_agency_involvement].present?
      intake[:owns_cell_phone] = row[:owns_cell_phone] if row[:owns_cell_phone].present?
      intake[:secondary_education] = row[:secondary_education] if row[:secondary_education].present?
      intake[:attending_college] = row[:attending_college] if row[:attending_college].present?
      intake[:health_insurance] = row[:health_insurance] if row[:health_insurance].present?
      intake[:client_lgbtq] = row[:client_lgbtq] if row[:client_lgbtq].present?
      intake[:pregnant_or_parenting] = row[:pregnant_or_parenting] if row[:pregnant_or_parenting].present?
      intake[:needs_shelter] = row[:needs_shelter] if row[:needs_shelter].present?
      intake[:referred_to_shelter] = row[:referred_to_shelter] if row[:referred_to_shelter].present?
      intake[:in_stable_housing] = row[:in_stable_housing] if row[:in_stable_housing].present?
      intake[:staff_believes_youth_under_24] = row[:staff_believes_youth_under_24] if row[:staff_believes_youth_under_24].present?
      intake[:requesting_financial_assistance] = row[:requesting_financial_assistance] if row[:requesting_financial_assistance].present?

      clients[row[:PersonalID]][:intakes] << intake
    end

    clients.each do |personal_id, data|
      client = data[:client]
      client[:data_source_id] = data_source.id
      client[:source_client] = GrdaWarehouse::Hud::Client.where(client).first_or_create()
    end

    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!

    # NOTE: this process assumes intakes are in chronological order for each client
    clients.each do |personal_id, data|
      destination_client_id = data[:client][:source_client].destination_client.id
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
      intake[:other_agency_involvement] ||= 'No'
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

      # The following fields are required at the DB level
      intake[:housing_status] ||= intake[:case_management_housing_status] || ''

      # But use the first engagement_date
      intake[:engagement_date] = data[:intakes].first[:engagement_date]
      intake[:client_id] = destination_client_id

      entry = GrdaWarehouse::YouthIntake::Entry.new(intake)
      if entry.valid?
        intakes_created += 1
      else
        intakes_failed += 1
        puts "Invalid record #{intake.inspect} #{entry.errors.full_messages.inspect}"
      end
      entry.save(validate: false)

      data[:referrals].each do |ref|
        ref[:client_id] = destination_client_id
        GrdaWarehouse::Youth::YouthReferral.create!(ref)
      end

      data[:case_managements].each do |ref|
        ref[:client_id] = destination_client_id
        GrdaWarehouse::Youth::YouthCaseManagement.create!(ref)
      end

      data[:financials].each do |ref|
        ref[:client_id] = destination_client_id
        GrdaWarehouse::Youth::DirectFinancialAssistance.create!(ref)
      end
    end
    puts "Valid: #{intakes_created} intakes; Invalid: #{intakes_failed} intakes"
  end
end