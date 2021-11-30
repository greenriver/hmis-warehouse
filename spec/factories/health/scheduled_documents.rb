FactoryBot.define do
  factory :scheduled_e_d_document, class: 'Health::ScheduledDocuments::EnrollmentDisenrollment' do
    name { 'ED' }
    protocol { 'sftp' }
    hostname { 'sftp' }
    username { 'user' }
    password { 'password' }
    file_path { '/sftp' }
  end
end
