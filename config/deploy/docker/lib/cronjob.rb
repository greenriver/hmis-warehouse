# An abstraction around a kubernetes cronjob
# https://github.com/k8s-ruby/k8s-ruby
class Cronjob
  attr_accessor :args
  attr_accessor :capacity_type
  attr_accessor :description
  attr_accessor :jobname
  attr_accessor :schedule_expression
  attr_accessor :k8s_image
  attr_accessor :k8s_service_account_name

  MAX_NAME_LENGTH = 52

  def initialize(description:, schedule_expression:, command:, capacity_type: 'spot')
    self.description = description
    self.schedule_expression = schedule_expression
    self.args = command
    self.jobname = namify(description)
    self.capacity_type = capacity_type
    self.k8s_image = ENV.fetch('K8S_IMAGE', 'set_k8s_image_somehow_to_test:v1') # provided by kyverno
    self.k8s_service_account_name = ENV.fetch('K8S_SERVICE_ACCOUNT_NAME', 'default') # provided by kyverno
  end

  def self.clear!
    dummy.clear!
  end

  def self.clear_defunct_vpas!
    dummy.clear_defunct_vpas!
  end

  def self.dummy
    new(description: 'none', schedule_expression: '', command: 'none', capacity_type: 'spot')
  end

  def clear!
    cron_list.each do |cron|
      Rails.logger.info "Deleting #{cron.metadata.namespace}/#{cron.metadata.name} (#{cron.metadata.annotations&.description})"
      crons.delete(cron.name)
    end
  end

  def clear_defunct_vpas!
    Rails.logger.info 'Looking for orphaned VPAs'
    existing_crons = Set.new(cron_list.map { |cron| cron.metadata.name })

    vpa_list.each do |vpa|
      if existing_crons.exclude?(vpa.metadata.labels['cronjob-name'])
        Rails.logger.warn "Deleting #{vpa.metadata.name} which is orphaned"
        vpas.delete(vpa.name)
      end
    end
  end

  def run!
    add_cron!
    upsert_vpa!
  end

  private

  def add_cron!
    Rails.logger.info "Adding #{jobname} with capacity #{capacity_type}"
    crons.create_resource(materialized_cronjob)
  end

  # vpa is a vertical pod autoscaler
  def upsert_vpa!
    Rails.logger.info "Upserting #{jobname} vertical pod autoscaler (VPA)"
    vpas.create_resource(materialized_vpa)
  rescue K8s::Error::Conflict
    Rails.logger.debug { "Already created a VPA for #{command}" }
    existing = vpas.get("cronjob-#{jobname}")
    existing[:spec][:updatePolicy] = materialized_vpa[:spec][:updatePolicy]
    existing[:spec][:resourcePolicy] = materialized_vpa[:spec][:resourcePolicy]
    vpas.update_resource(existing)
  end

  def namify(string)
    string.
      gsub(/[^a-zA-Z0-9]/, '-').
      sub(/interruptable-(false|true)/, '').
      sub(/rake-/, '').
      squeeze('-')[0, MAX_NAME_LENGTH].sub(/-+$/, '')
  end

  def materialized_cronjob
    K8s::Resource.new(
      YAML.load(
        ERB.new(configmap.data['cronjob.yaml']).result(binding),
      ),
    )
  end

  # vertical pod autoscaler
  def materialized_vpa
    K8s::Resource.new(
      YAML.load(
        ERB.new(configmap.data['vpa.yaml']).result(binding),
      ),
    )
  end

  def cron_list
    crons.list(labelSelector: { 'cron-source' => 'rails' })
  end

  def vpa_list
    vpas.list(labelSelector: { 'cron-source' => 'rails' })
  end

  def namespace
    'warehouse-qa-staging'
  end

  def crons
    client.api('batch/v1').resource('cronjobs', namespace: namespace)
  end

  def vpas
    client.api('autoscaling.k8s.io/v1').resource('verticalpodautoscalers', namespace: namespace)
  end

  def configmap
    client.
      api('v1').
      resource('configmaps', namespace: namespace).
      list(labelSelector: { 'cron-source' => 'rails' }).
      first
  end

  def client
    @client ||=
      if ENV['KUBE_CONFIG_PATH'].present?
        kube_config = File.read(ENV['KUBE_CONFIG_PATH'])

        # We can't have host networking because that will mess up connecting to redis/db/etc. in development
        # We can't easily/portably forward to a kind cluster running on the host
        # So, we connect over a docker network...
        # - Kind running a cluster already on a network called "kind" likely
        # - docker compose override getting this container on the kind network
        # - Some .envrc scripting to populate this value from docker network inspect and docker container ls
        # - Doesn't distinguish between multiple kind clusters
        server_ip = ENV.fetch('K8S_API_HOST_AND_PORT')
        File.write('.kube_config', kube_config.gsub(/127\.0\.0\.1:\d+/, server_ip))

        K8s::Client.config(K8s::Config.load_file('.kube_config'))
      else
        K8s::Client.in_cluster_config
      end
  end
end
