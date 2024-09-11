require 'rails_helper'

RSpec.describe 'Import Two Epics', type: :model do
  before(:all) do
    cleanup
    import
  end

  after(:all) do
    cleanup
  end

  it 'Only creates 1 patient for each medicaid ID' do
    medicaid_id_count = Health::EpicPatient.pluck(:medicaid_id).uniq.count
    expect(Health::Patient.count).to eq medicaid_id_count
  end

  it 'attaches QAs from both imports' do
    Health::Patient.find_each do |patient|
      expect(patient.qualifying_activities.count).to eq(patient.epic_qualifying_activities.count)
    end
  end

  it 'attaches medications from both imports' do
    Health::Patient.find_each do |patient|
      expect(patient.medications.count).to eq(patient.epic_medications.count)
    end
  end

  it 'attaches appointments from both imports' do
    Health::Patient.find_each do |patient|
      expect(patient.appointments.count).to eq(patient.epic_appointments.count)
    end
  end

  it 'attaches visits from both imports' do
    Health::Patient.find_each do |patient|
      expect(patient.visits.count).to eq(patient.epic_visits.count)
    end
  end

  it 'de-dups team members' do
    Health::Patient.bh_cp.find_each do |patient| # Pilot patients do not get team members via importer
      expect(patient.team_members.pluck(:email).compact).to contain_exactly(*patient.epic_team_members.pluck(:email).uniq.compact)
    end
  end

  # it 'smoke test' do
  #   binding.pry
  # end

  def import
    configs = [
      OpenStruct.new(
        data_source_name: 'First',
        destination: 'var/health/testing',
        test_files: 'spec/fixtures/files/health/epic/simple/*.csv',
      ),
      OpenStruct.new(
        data_source_name: 'Second',
        destination: 'var/health/testing2',
        test_files: 'spec/fixtures/files/health/epic/second/*.csv',
      ),
    ]

    configs.each do |config|
      ds = Health::DataSource.find_or_create_by!(name: config.data_source_name)
      FileUtils.mkdir_p(config.destination) unless Dir.exist?(config.destination)
      FileUtils.cp(Dir.glob(config.test_files), config.destination)
      Health::Tasks::ImportEpic.new(load_locally: true, configs: [config]).run!
      create_patients(ds.id)
    end
    # Health::Tasks::PatientClientMatcher.new.run! # only processes pilot patients, so skipped
    Health::EpicTeamMember.process!
    Health::EpicQualifyingActivity.update_qualifying_activities!
    Health::EpicThrive.update_thrive_assessments!
    Health::Patient.update_demographic_from_sources
  end

  def create_patients(data_source_id)
    Health::EpicPatient.where(data_source_id: data_source_id).each do |epic_patient|
      Health::Patient.find_or_create_by!(medicaid_id: epic_patient.medicaid_id) do |patient|
        patient.id_in_source = epic_patient.id_in_source
        patient.data_source_id = epic_patient.data_source_id
      end
    end
  end

  def cleanup
    Health.models_by_health_filename.values.each(&:delete_all)
    [
      Health::QualifyingActivity,
      HealthThriveAssessment::Assessment,
      Health::Team::Member,
      Health::HousingStatus,
      Health::Patient,
      Health::DataSource,
    ].each(&:delete_all)
  end
end
