require 'aws-sdk-rds'
#require 'byebug'

class MakeRDS
  attr_accessor :aws_security_group
  attr_accessor :name

  AWS_PROFILE = ENV.fetch('AWS_PROFILE')
  MAJOR_VERSION = '12' # of postgres
  MINOR_VERSION = '2'  # of postgres
  VERSION = "#{MAJOR_VERSION}.#{MINOR_VERSION}"
  DB_CLASS= 'db.m5.large'
  MULTI_AZ = false
  STORAGE = 50

  def initialize(name:)
    self.name = name
    self.aws_security_group = ENV.fetch('DB_SECURITY_GROUP') { 'sg-4477e03a' }
  end

  def run!
    _parameter_group!
    _make!
  end

  private

  def _parameter_group!
    begin
      rds.create_db_parameter_group(
        db_parameter_group_name: "pg-#{MAJOR_VERSION}-custom-parameter-group",
        db_parameter_group_family: "postgres#{MAJOR_VERSION}",
        description: "Defaults plus encrypted connection enforcement",
      )
    rescue Aws::RDS::Errors::DBParameterGroupAlreadyExists
      puts "Not creating paramter group. It already exists"
    end

    rds.modify_db_parameter_group(
      db_parameter_group_name: "pg-#{MAJOR_VERSION}-custom-parameter-group",
      parameters: [
        {
          parameter_name: "rds.force_ssl",
          parameter_value: '1',
          apply_method: "pending-reboot",
        }
      ]
    )
  end

  def _make!
    begin
      rds.create_db_instance({
        allocated_storage: STORAGE,
        engine: 'postgres',
        engine_version: VERSION,
        db_instance_class: DB_CLASS,
        db_instance_identifier: name,
        master_username: 'postgres',
        master_user_password: @pass=SecureRandom.hex(16), #db_password,
        auto_minor_version_upgrade: true,
        multi_az: MULTI_AZ,
        storage_encrypted: true,
        backup_retention_period: 15,
        enable_performance_insights: true,
        copy_tags_to_snapshot: true,
        storage_type: "gp2",
        publicly_accessible: false,
        vpc_security_group_ids: [aws_security_group],
        db_parameter_group_name: "pg-#{MAJOR_VERSION}-custom-parameter-group",
        deletion_protection: true,
        max_allocated_storage: 150, # in GB
        tags: [
          {
            key: 'Client',
            value: name,
          },
          {
            key: 'Name',
            value: "#{name} Database",
          },
          {
            key: 'Role',
            value: "Database",
          },
          {
            key: 'Created_By',
            value: ENV['USER']||'unknown',
          },
        ],
      })
      puts "Creating Instance"

      puts "password: #{@pass}"
    rescue Aws::RDS::Errors::DBInstanceAlreadyExists
      puts "Not creating instance. It already exists"
    end
  end

  define_method(:rds) { Aws::RDS::Client.new(profile: AWS_PROFILE) }
end
