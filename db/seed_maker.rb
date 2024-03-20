###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

# To use SeedMaker outside of `db:seed` call `require ./db/seed_maker`
class SeedMaker
  def setup_fake_user
    return if User.find_by(email: 'noreply@example.com').present?

    User.transaction do
      # Add roles
      admin = Role.where(name: 'Admin').first_or_create
      # a role that can edit permissions and create users
      admin.update(can_edit_users: true, can_edit_roles: true)
      coc_staff = Role.where(name: 'CoC Staff').first_or_create
      # a role with some basic access
      coc_staff.update(
        can_edit_data_sources: true,
        can_upload_hud_zips: true,
        can_search_window: true,
        can_view_clients: true,
        can_view_full_client_dashboard: true,
        can_view_all_reports: true,
        can_view_assigned_reports: true,
        can_view_all_hud_reports: true,
      )

      # Add a user.  This should not be added in production
      return if Rails.env =~ /production|staging/

      agency = Agency.where(name: 'Sample Agency').first_or_create
      initial_password = Faker::Internet.password(min_length: 16)
      user = User.new
      user.email = 'noreply@example.com'
      user.first_name = 'Sample'
      user.last_name = 'Admin'
      user.password = user.password_confirmation = initial_password
      user.confirmed_at = Time.now
      user.permission_context = 'acls' # Use `user.permission_context = 'role_based'` for legacy permissions
      user.agency_id = agency.id
      user.save!
      # legacy access
      admin.add(user)
      coc_staff.add(user)
      user_group = UserGroup.where(name: 'Fake Admins').first_or_create
      user_group.add(user)
      all_ds_entity_collection = Collection.system_collection(:data_sources)
      AccessControl.create(role: admin, collection: all_ds_entity_collection, user_group: user_group)
      AccessControl.create(role: coc_staff, collection: all_ds_entity_collection, user_group: user_group)
      puts "Created initial admin email: #{user.email}  password: #{user.password}"
    end
  end

  def health_disenrollment_reasons
    [
      { reason_code: '01', reason_description: 'Loss of Eligibility/Case Closing' },
      { reason_code: '02', reason_description: 'Newborn - As a Result of NOB' },
      { reason_code: '03', reason_description: 'Change of Plan Type (MHO Use Only)' },
      { reason_code: '04', reason_description: 'Change Category of Assistance/Ineligible' },
      { reason_code: '05', reason_description: 'Moved Out of Service Area' },
      { reason_code: '06', reason_description: 'Active TPL Segment' },
      { reason_code: '07', reason_description: 'Waivered Services (MHO Use Only)' },
      { reason_code: '08', reason_description: 'PCC/MCO Status Change' },
      { reason_code: '09', reason_description: 'PCC Status Change - Moved Out of State' },
      { reason_code: '10', reason_description: 'PCC Status Change - Moved to Other Practice' },
      { reason_code: '11', reason_description: 'MSCP Still Restricted (MHO Use Only)' },
      { reason_code: '12', reason_description: 'MSCP Restricted, No Longer Necessary' },
      { reason_code: '13', reason_description: 'Misunderstood MCO or PCC Plan Network' },
      { reason_code: '14', reason_description: 'Misunderstood MCO or PCC Plan Referral' },
      { reason_code: '15', reason_description: 'No Answer/Answering Machine When Calling Provider' },
      { reason_code: '16', reason_description: 'No Call Back from Provider' },
      { reason_code: '17', reason_description: 'Referred (by family, friend, etc.)' },
      { reason_code: '18', reason_description: 'Moved Within Service Area' },
      { reason_code: '20', reason_description: 'Language/Cultural Barrier (Interpretation Service)' },
      { reason_code: '21', reason_description: 'Language/Cultural Barrier with Office Staff' },
      { reason_code: '22', reason_description: 'Language/Cultural Barrier with Doctor' },
      { reason_code: '23', reason_description: 'Too Long to Get an Appointment for Initial Visit' },
      { reason_code: '24', reason_description: 'Too Long to Get an Appointment when Sick/Urgent' },
      { reason_code: '25', reason_description: 'Did not Like Doctor\'s Personal Manner' },
      { reason_code: '26', reason_description: 'Provider\'s Office was Unsanitary' },
      { reason_code: '27', reason_description: 'Member Did not Have Privacy for Exam' },
      { reason_code: '28', reason_description: 'Member Utilizing VA Benefits' },
      { reason_code: '29', reason_description: 'MCO Extra Programs' },
      { reason_code: '30', reason_description: 'Mass Update (MHO Use Only)' },
      { reason_code: '31', reason_description: 'Dissatisfaction with MH/SA Network' },
      { reason_code: '32', reason_description: 'Difficulty Accessing MH/SA Services' },
      { reason_code: '33', reason_description: 'Difficulty Accessing Pharmacy Service' },
      { reason_code: '34', reason_description: 'No Longer Eligible for Special Program' },
      { reason_code: '35', reason_description: 'Panel Reopened' },
      { reason_code: '36', reason_description: 'Transfer Back to PCC After Conversion to MCO' },
      { reason_code: '37', reason_description: 'Transferring as Result of Assignment' },
      { reason_code: '38', reason_description: 'Provider Profile Incorrect' },
      { reason_code: '39', reason_description: 'Provider Network Unacceptable' },
      { reason_code: '40', reason_description: 'Prefer Previous Doctor' },
      { reason_code: '41', reason_description: 'Doctor no Longer Accepting Plan' },
      { reason_code: '42', reason_description: 'Waited too Long in Waiting Room' },
      { reason_code: '43', reason_description: 'Access to Preferred Specialist' },
      { reason_code: '44', reason_description: 'Change in COA/Upgrade' },
      { reason_code: '45', reason_description: 'Doctor Refused to Join Network' },
      { reason_code: '46', reason_description: 'Assignment to Inappropriate Provider Type' },
      { reason_code: '47', reason_description: 'Dissatisfied with Healthcare' },
      { reason_code: '48', reason_description: 'Dissatisfied with Appeal Decision' },
      { reason_code: '49', reason_description: 'Death (MHO Use Only)' },
      { reason_code: '50', reason_description: 'Transportation Problem' },
      { reason_code: '51', reason_description: 'Misunderstood MCO Program' },
      { reason_code: '52', reason_description: 'Difficult to Contact Doctor' },
      { reason_code: '53', reason_description: 'Problem Receiving Emergency Care' },
      { reason_code: '54', reason_description: 'Language Barrier' },
      { reason_code: '55', reason_description: 'Poor Handicapped Access' },
      { reason_code: '56', reason_description: 'Takes too Long to Get an Appointment' },
      { reason_code: '57', reason_description: 'Did not Like Doctor' },
      { reason_code: '58', reason_description: 'Dissatisfaction with MCO Specialist Care' },
      { reason_code: '59', reason_description: 'Dissatisfaction with MH/SA Services' },
      { reason_code: '60', reason_description: 'MHMA Segment Closed with MCO Enrollment' },
      { reason_code: '61', reason_description: 'MHO Approved Disenrollment' },
      { reason_code: '62', reason_description: 'Other' },
      { reason_code: '63', reason_description: 'Health Care Needs Changed' },
      { reason_code: '64', reason_description: 'Misunderstood PCC Program' },
      { reason_code: '65', reason_description: 'Turned 65 - Loss of Eligibility (MHO Use Only)' },
      { reason_code: '66', reason_description: 'Dissatisfied with Prescribed Treatment' },
      { reason_code: '67', reason_description: 'Dissatisfied with PCP Prescription Practice' },
      { reason_code: '68', reason_description: 'Did not Meet Clinical Needs Requirements' },
      { reason_code: '69', reason_description: 'Free Transfer' },
      { reason_code: '70', reason_description: 'Medicare (MHO Use Only)' },
      { reason_code: '71', reason_description: 'LTC (MHO Use Only)' },
      { reason_code: '72', reason_description: 'MCB (MHO Use Only)' },
      { reason_code: '73', reason_description: 'Exempted from Managed Care Program' },
      { reason_code: '74', reason_description: 'Did not Like Office Staff\'s Personal Manner' },
      { reason_code: '75', reason_description: 'Received Poor Medical Treatment' },
      { reason_code: '76', reason_description: 'Problems Receiving Authorization for Referrals' },
      { reason_code: '77', reason_description: 'DSS/DYS - Related' },
      { reason_code: '78', reason_description: 'Old DYS Code - No Longer in Use' },
      { reason_code: '79', reason_description: 'Takes too Long to See Doctor in Office' },
      { reason_code: '80', reason_description: 'Request by MCO (MHO Use Only)' },
      { reason_code: '81', reason_description: 'PCC Plan Approved' },
      { reason_code: '82', reason_description: 'Improperly Enrolled' },
      { reason_code: '83', reason_description: 'Transferred as a Result of Hospice Care' },
      { reason_code: '84', reason_description: 'Per Request of Enrollment Form (HBA 3 Use)' },
      { reason_code: '85', reason_description: 'Fair Hearing Appeal Decision' },
      { reason_code: '86', reason_description: 'Opt Out of CommCare' },
      { reason_code: '87', reason_description: 'Non-Payment of Premium' },
      { reason_code: '88', reason_description: 'Multiple Providers Due to Link/Unlink' },
      { reason_code: '89', reason_description: 'Chronic Provider Access Problems' },
      { reason_code: '90', reason_description: 'Misused MCO Services (MHO Use Only)' },
      { reason_code: '91', reason_description: 'Enrolled in SCO' },
      { reason_code: '92', reason_description: 'Homeless' },
      { reason_code: '93', reason_description: 'CommCare COA Change' },
      { reason_code: '94', reason_description: 'CommCare Open Enrollment Request' },
      { reason_code: '95', reason_description: 'Loss Elig. - Special Population Member Turns 22' },
      { reason_code: '96', reason_description: 'Returned Mail' },
      { reason_code: '97', reason_description: 'Provider Practice Closed, MBHP Remains Open' },
      { reason_code: '99', reason_description: 'RS/MSCP Mass Change (MHO Use Only)' },
      { reason_code: 'AB', reason_description: 'Discharged to Nursing Facility' },
      { reason_code: 'AC', reason_description: 'Discharged to Acute Facility' },
      { reason_code: 'AD', reason_description: 'Discharged to Leave of Absence' },
      { reason_code: 'AE', reason_description: 'Transferred to a Long Term Care Facility' },
      { reason_code: 'AF', reason_description: 'Member No Longer Wants Hospice Services (Revocation)' },
      { reason_code: 'AG', reason_description: 'Declined Services (Nursing, etc.)' },
      { reason_code: 'AH', reason_description: 'Transferred to MCO Special Program' },
      { reason_code: 'AI', reason_description: 'Enrolled in All-Inclusive Managed Care Plan' },
      { reason_code: 'AJ', reason_description: 'Enrolled in PACE' },
      { reason_code: 'AK', reason_description: 'Discharged to Home/Community' },
      { reason_code: 'AL', reason_description: 'Discharged to Rest Home' },
      { reason_code: 'AM', reason_description: 'Left Against Medical Advice' },
      { reason_code: 'AN', reason_description: 'Member Opt-out' },
      { reason_code: 'AP', reason_description: 'Member Enrolled in HCBS Waiver' },
      { reason_code: 'AQ', reason_description: 'ICF-MR Admission' },
      { reason_code: 'AR', reason_description: 'Loss of Medicare A and/or B' },
      { reason_code: 'AS', reason_description: 'Member enrolled in Medicare Part C (Medicare Advantage)' },
      { reason_code: 'AT', reason_description: 'Change of Medicare Part D Plan' },
      { reason_code: 'AZ', reason_description: 'Default Stop Reason Code' },
      { reason_code: 'B6', reason_description: 'CommP - Enrollee Requested Change' },
      { reason_code: 'B7', reason_description: 'CommP - ACO/MCO Requested Change' },
      { reason_code: 'B8', reason_description: 'CommP - Declined' },
      { reason_code: 'B9', reason_description: 'CommP - Unreachable' },
      { reason_code: 'BA', reason_description: 'CommP - Disengaged' },
      { reason_code: 'BB', reason_description: 'CommP - Moved out of Geographic Area' },
      { reason_code: 'BC', reason_description: 'CommP - Graduated' },
      { reason_code: 'BD', reason_description: 'CommP - Medical Exception' },
      { reason_code: 'BH', reason_description: 'CommP - ACCS Aid Cat Change' },
      { reason_code: 'BI', reason_description: 'CommP - AUTO-Re-Enrollment - ACCS Special Rule' },
      { reason_code: 'BJ', reason_description: 'CommP - AUTO-Transfer due ACCS enrollment (change from ACCS to PACC)' },
      { reason_code: 'BK', reason_description: 'CommP - AUTO-Transfer due Addition of MC Eligibility (ACCS2 to ACCS1 or PACC2 to PACC1)' },
      { reason_code: 'BL', reason_description: 'CommP - AUTO-Disenrollment due PACT enrollment' },
      { reason_code: 'BM', reason_description: 'CommP - AUTO-Disenrollment due ACCS enrollment' },
      { reason_code: 'EO', reason_description: 'Service Area Restriction Enrollment Override' },
      { reason_code: 'P0', reason_description: 'PSFE - Admin' },
      { reason_code: 'P1', reason_description: 'PSFE - Moved outside of the Service Area in which the MCO operates' },
      { reason_code: 'P2', reason_description: 'PSFE - MCO has not provided access to health care providers that meets enrollee health care needs' },
      { reason_code: 'P3', reason_description: 'PSFE - Enrollee is homeless, and MCO cannot accommodate the geographic needs of the member' },
      { reason_code: 'P4', reason_description: 'PSFE - MCO substantially violated a material provision of its contract in relation to the enrollee' },
      { reason_code: 'P5', reason_description: 'PSFE - MassHealth imposes a sanction on the MCO which allow enrollment termination without cause' },
      { reason_code: 'SC', reason_description: 'Member Opt-out from SCO' },
      { reason_code: 'TB', reason_description: 'Auto-Disenroll - PCCB-CPCCB and ACOB No Longer Affiliated' },
      { reason_code: 'Z0', reason_description: 'Auto-Disenroll - Death' },
      { reason_code: 'Z1', reason_description: 'Auto-Disenroll - Ineligible Aid Cat/Loss of Medicaid Eligibility' },
      { reason_code: 'Z2', reason_description: 'Auto-Disenroll - Comprehensive Verified TPL' },
      { reason_code: 'Z3', reason_description: 'Auto-Disenroll - Medicare A or B' },
      { reason_code: 'Z4', reason_description: 'Auto-Disenroll - Mutually Exclusive Program' },
      { reason_code: 'Z5', reason_description: 'BATCH - Dental Eligibility Review' },
      { reason_code: 'Z6', reason_description: 'Auto-Disenroll - Excluded from Managed Care' },
      { reason_code: 'Z7', reason_description: 'Auto-Disenroll - Active Spenddown' },
      { reason_code: 'Z8', reason_description: 'Auto-Disenroll - Maximum Age - Loss of Eligibility' },
      { reason_code: 'Z9', reason_description: 'Auto-Disenroll - Active Long Term Care' },
      { reason_code: 'ZA', reason_description: 'Auto-Disenroll - Newborn - As a Result of NOB' },
      { reason_code: 'ZB', reason_description: 'Auto-Disenroll - LTC Benefit Exhaustion' },
      { reason_code: 'ZC', reason_description: 'Auto-Disenroll - Min Age For PGM Enrollment Not Met' },
      { reason_code: 'ZD', reason_description: 'Auto-Disenroll - AR03 Temporary Eligibility' },
      { reason_code: 'ZE', reason_description: 'Auto-Disenroll - Member Opt-out' },
      { reason_code: 'ZF', reason_description: 'Auto disenrollment - ICF-MR Admission' },
      { reason_code: 'ZG', reason_description: 'Auto disenrollment - Loss of Medicare A and/or B' },
      { reason_code: 'ZH', reason_description: 'Auto Disenroll - Member gained Medicare Part C (Medicare Advantage)' },
      { reason_code: 'ZI', reason_description: 'NON-STD to STD-Disabled Transfer' },
      { reason_code: 'ZJ', reason_description: 'Auto Disenroll - Change of Medicare Part D Plan' },
      { reason_code: 'ZK', reason_description: 'Auto-Disenroll - Member enrolled in HCBS Waiver' },
      { reason_code: 'ZL', reason_description: 'Auto-Disenroll - Higher Aid Category Forced Transfer' },
      { reason_code: 'ZM', reason_description: 'Auto-Disenroll - Mass Transfer' },
      { reason_code: 'ZN', reason_description: 'Plan Change - DT Less Rich Aid Cat Forced Transfer' },
      { reason_code: 'ZT', reason_description: 'Auto-Disenroll - Loss of TPL/Medicare' },
    ].freeze
  end

  def maintain_health_seeds
    Health::DataSource.where(name: 'BHCHP EPIC').first_or_create
    Health::DataSource.where(name: 'Patient Referral').first_or_create
    GrdaWarehouse::DataSource.where(short_name: 'Health').first_or_create do |ds|
      ds.name = 'Health'
      ds.authoritative = true
      ds.visible_in_window = false
      ds.authoritative_type = 'health'
      ds.save
    end

    Health::Cp.sender.first_or_create do |sender|
      sender.update(
        mmis_enrollment_name: 'COORDINATED CARE HUB',
        trace_id: 'OPENPATH00',
      )
    end

    health_disenrollment_reasons.each do |reason|
      Health::DisenrollmentReason.where(reason).first_or_create
    end
  end

  def maintain_data_sources
    GrdaWarehouse::DataSource.where(short_name: 'Warehouse').first_or_create do |ds|
      ds.name = 'HMIS Warehouse'
      ds.save
    end
  end

  def maintain_lookups
    HudUtility2024.cocs.each do |code, name|
      coc = GrdaWarehouse::Lookups::CocCode.where(coc_code: code).first_or_initialize
      coc.update(official_name: name)
    end
    GrdaWarehouse::Lookups::YesNoEtc.transaction do
      GrdaWarehouse::Lookups::YesNoEtc.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::YesNoEtc.import(columns, HudUtility2024.no_yes_reasons_for_missing_data_options.to_a)
    end
    GrdaWarehouse::Lookups::LivingSituation.transaction do
      GrdaWarehouse::Lookups::LivingSituation.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::LivingSituation.import(columns, HudUtility2024.living_situations.to_a)
    end
    GrdaWarehouse::Lookups::ProjectType.transaction do
      GrdaWarehouse::Lookups::ProjectType.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::ProjectType.import(columns, HudUtility2024.project_types.to_a)
    end
    GrdaWarehouse::Lookups::FundingSource.transaction do
      GrdaWarehouse::Lookups::FundingSource.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::FundingSource.import(columns, HudUtility2024.funding_sources.to_a)
    end
    GrdaWarehouse::Lookups::Gender.transaction do
      GrdaWarehouse::Lookups::Gender.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::Gender.import(columns, HudUtility2024.genders.to_a)
    end
    GrdaWarehouse::Lookups::Relationship.transaction do
      GrdaWarehouse::Lookups::Relationship.delete_all
      columns = [:value, :text]
      GrdaWarehouse::Lookups::Relationship.import(columns, HudUtility2024.relationships_to_hoh.to_a)
    end
  end

  def install_shapes
    return unless GrdaWarehouse::Shape::Installer.any_needed?

    begin
      Rake::Task['grda_warehouse:get_shapes'].invoke
    rescue Exception => e
      Rails.logger.tagged('shapes') do
        Rails.logger.fatal "Could not run shape importer: #{e.message}"
      end
    end
  end

  # These tables are partitioned with inheritance and need to have triggers and
  # functions that schema loading doesn't include.  This will ensure that they
  # exist on each deploy
  def ensure_db_triggers_and_functions
    Reporting::MonthlyReports::Base.ensure_triggers
  end

  def maintain_system_groups
    AccessGroup.maintain_system_groups
    Collection.maintain_system_groups(group: :data_sources)
  end

  def setup_fake_health_data
    return unless Rails.env.development?
    return if Health::PatientReferral.exists?

    FactoryBot.create_list(:patient_referral, 50)
    FactoryBot.create(:accountable_care_organization)
    FactoryBot.create(:health_agency, name: 'GR Health')
    health_admin = Role.create(
      health_role: true,
      name: 'Health Admin',
      can_administer_health: true,
      can_view_aggregate_health: true,
      can_manage_health_agency: true,
    )
    u = User.not_system.first
    u.health_roles << health_admin
    Health::AgencyUserSaver.new(user_id: u.id, agency_ids: Health::Agency.pluck(:id)).save
  end

  def setup_hmis_admin_access
    return unless ENV['HMIS_HOSTNAME'].present?
    return unless Rails.env.development?

    # Create HMIS Administrator role
    hmis_admin_role = Hmis::Role.where(can_administer_hmis: true).first_or_create! do |role|
      role.name = 'HMIS Administrator'
      role.can_view_project = true
      role.can_view_clients = true
    end

    # Create HMIS Data Source
    hmis_ds = GrdaWarehouse::DataSource.source.where(hmis: ENV['HMIS_HOSTNAME']).first_or_create! do |ds|
      ds.name = 'HMIS'
      ds.short_name = 'HMIS'
      ds.authoritative = true
    end

    return if hmis_admin_role.users.any?

    # Give a user HMIS Admin access by setting up a basic Access Control List
    user = Hmis::User.not_system.first
    return unless user.present?

    # Create Access Group (Collection) with data source access
    access_group = Hmis::AccessGroup.where(name: 'All HMIS Projects').first_or_create!
    access_group.add_viewable(hmis_ds)
    # Create User Group
    user_group = Hmis::UserGroup.where(name: 'Admin Users').first_or_create!
    user_group.add(user)
    # Create Access Control
    Hmis::AccessControl.where(
      role: hmis_admin_role,
      access_group: access_group,
      user_group: user_group,
    ).first_or_create!
    puts "#{user.name} is now an HMIS Administrator. Go to https://hmis-warehouse.dev.test/hmis_admin/roles to manage data access and permissions."
  end

  def load_hmis_data
    return unless ENV['ENABLE_HMIS_API'] == 'true'

    builder = ::HmisUtil::JsonForms.new
    builder.seed_all
    builder.create_default_occurrence_point_instances! if Rails.env.development?
  end

  def populate_internal_system_choices
    return unless ENV['ENABLE_HMIS_API'] == 'true'

    HmisExternalApis::InternalSystem::NAMES.each do |name|
      sys = HmisExternalApis::InternalSystem.where(name: name).first_or_initialize
      if sys.new_record?
        Rails.logger.info "Creating #{name} internal system choice for Admin UI"
        sys.save!
      end
    end
  end

  def run_all
    ensure_db_triggers_and_functions
    setup_fake_user if Rails.env.development?
    setup_fake_health_data
    maintain_data_sources
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    maintain_health_seeds
    setup_hmis_admin_access
    load_hmis_data
    install_shapes
    maintain_lookups
    GrdaWarehouse::Help.setup_default_links
    maintain_system_groups
    populate_internal_system_choices
    GrdaWarehouse::SystemColor.ensure_colors
    Translation::maintain_keys
  end
end
