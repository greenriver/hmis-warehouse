class DbFirewallMaintainer
  attr_accessor :ip
  attr_accessor :description
  attr_accessor :expiry
  attr_accessor :bouncer_security_group_id

  def initialize
    self.expiry = DbCredential.hours_available
    self.bouncer_security_group_id = ENV['BOUNCER_SECURITY_GROUP_ID']
  end

  def firewall_active?
    self.bouncer_security_group_id.present?
  end

  def remove!(ip:)
    return unless firewall_active?

    self.ip = ip
    self.description = nil

    # find matches
    relevant = security_group.ip_permissions.select do |rule|
      self.ip == rule.ip_ranges.first.cidr_ip
    end

    raise "couldn't find the rule to remove" if relevant.blank?

    Rails.logger.info "Removing #{ip} access to database"

    relevant.each do |rule|
      self.description = rule.ip_ranges.first.description

      result = security_group.revoke_ingress(template)

      if result.nil?
        raise "removal of rule failed. did the description and ip match?"
      end
    end
    puts "Removed #{ip}"
  end

  def add!(ip:, description:)
    return unless firewall_active?

    self.ip = ip
    self.description = description

    template_copy = template.dup
    security_group.authorize_ingress(template_copy)
    puts "Added #{ip}"
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    Rails.logger.warn "Did not add a rule for #{ip}: It already exists"
  end

  def list
    security_group.ip_permissions.select do |perm|
      _relevant_perm?(perm)
    end
  end

  def update!
    return unless firewall_active?

    GrdaWarehouse::WarehouseReports::ReportDefinition.with_advisory_lock('db_firewall_maintainer') do
      security_group.ip_permissions.each do |perm|
        next unless _relevant_perm?(perm)

        self.ip = perm.ip_ranges.first.cidr_ip

        remove!(ip: ip) if _needs_removal?
      end

      desired_creds.each do |creds|
        self.ip =  creds.ip
        add!(ip: self.ip, description: creds.email)
      end
    end
  end

  # def tags
  #   security_group.tags
  # end

  def push_bouncer_credentials!
    raise "implement"
  end

  def desired_creds
    @desired_creds ||=
      DbCredential.all.preload(:user).select do |creds|
        (creds.user.last_activity_at + expiry) > Time.now
      end.map do |creds|
        OpenStruct.new({
          username: creds.username,
          password: creds.password,
          ip: "#{creds.user.current_sign_in_ip}/32",
          email: creds.user.email
        })
      end
  end

  private

  def desired_ips
    @desired_ips ||=
      desired_creds.map do |creds|
        creds.ip
      end.uniq
  end

  def bouncer_userlist
    desired_creds.
      sort_by { |creds| creds.username }.
      map { |creds| %<"#{creds.username}" "#{creds.password}"> }.
      join("\n")
  end

  def _needs_adding?
    self.ip.in?(desired_ips)
  end

  def _needs_removal?
    !_needs_adding?
  end

  def template
    {
      ip_permissions: [
        {
          from_port: 5432,
          ip_protocol: "tcp",
          ip_ranges: [
            {
              cidr_ip: ip,
              description: description,
            },
          ],
          to_port: 5432,
        },
      ],
    }
  end

  def _relevant_perm?(perm)
    perm.from_port <= 5432 && 5432 <= perm.to_port
  end

  def security_group
    @security_group ||= Aws::EC2::SecurityGroup.new(bouncer_security_group_id)
  end
end
