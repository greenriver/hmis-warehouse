require 'aws-sdk-ecs'
require 'aws-sdk-ecr'
require_relative 'deployer'
require 'awesome_print'

class EcsTools
  HOST  = 'ecs0.openpath.host'
  IMAGE = ENV['IMAGE']

  def shell
    containers = `ssh #{HOST} "docker ps -a -n 10"`

    container_id = \
      containers.
        split(/\n/).
        grep(/#{IMAGE}/).
        first.
        split(/\s/).
        first

    puts "Using container #{container_id} for a shell"

    puts "making image we can ssh to"
    system("ssh #{HOST} 'docker commit #{container_id} shell'")

    exec("ssh -t #{HOST} 'docker run --rm -ti shell /bin/sh'")
  end

  # https://github.com/jorgebastida/awslogs
  def logs(group)
    if group.nil?
      puts "first parameter is the group"
      system('awslogs groups')
      exit
    end

    exec("awslogs get #{group} ALL --watch")
  end

  def poll_state_until_stable!(cluster, failures: true)
    puts 'These are only services, not tasks (e.g. migrations won\'t appear here)'
    puts 'PRIMARY: The most recently pushed task definition. These are the desired things we want or are deployed'
    puts 'ACTIVE: This is what\'s currently running and will show up when we have not yet transfered all the containers to be primary'
    puts 'INACTIVE: An old deployment. You might never see this. They\'re ephemeral.'
    puts ''

    all_arns = \
      ecs.list_services(cluster: cluster).flat_map do |service_set|
        service_set.to_h[:service_arns]
      end

    template = '%4s | %39s | %2s | %3s | %7s | %7s | %7s | %27s | %27s'

    bad = true

    finished = ->(s) { s.deployments.length == 1 && s.deployments[0].status == 'PRIMARY' && s.deployments[0].desired_count == s.deployments[0].running_count }

    while bad do
      puts format(template, 'Good', 'Service Name', 'LB', '#', 'Status', 'pending', 'running', 'created', 'updated')
      puts '-' * 147

      services = all_arns.each_slice(10).flat_map do |arns|
        ecs.describe_services(services: arns, cluster: cluster).services
      end.sort_by do |service|
        order = finished.call(service) ? 0 : 1
        [order, service.service_name]
      end

      bad = false

      services.each do |service|
        deployments = service.deployments

        finished_deployment = finished.call(service) #deployments.length == 1 && deployments[0].status == 'PRIMARY' && deployments[0].desired_count == deployments[0].running_count

        next if failures && finished_deployment

        bad ||= !finished_deployment

        header = [
          finished_deployment ? 'yes' : '',
          service.service_name,
          service.load_balancers == [] ? '' : '*',
        ]

        deployments.each do |deployment|
          row = []
          row << deployment.task_definition.split(/:/).last.to_i
          row << deployment.status
          row << deployment.pending_count == '0' ? '' : deployment.pending_count
          row << "#{deployment.running_count}/#{deployment.desired_count}"
          row << deployment.created_at
          row << deployment.updated_at

          puts format(template, *(header + row))

          # if failures
          #   puts service.events.map(&:message)
          #   debugger
          # end

          header =  ['', '', '']
        end
        puts '-' * 147

        # puts "   Events:"
        # service.events.take(5).each do |event|
        #   message = event.message
        #   message.sub!(/.service #{service.service_name}./, '')
        #   puts "      #{event.created_at}: #{message}"
        # end
      end

      sleep 20 if bad
    end
  end

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/agent-update-ecs-ami.html
  # we have ansible that does this another way but doesn't work for some reason.
  def update_ecs_agents!(cluster)
    results = ecs.list_container_instances(cluster: cluster)
    container_instances = results.to_h[:container_instance_arns]

    container_instances.each do |ci|
      begin
        results = ecs.update_container_agent(
          cluster: cluster,
          container_instance: ci,
        )
        #puts results.ai
        puts "Scheduled update for agent on #{ci}. Only doing this one so we don't restart all the agents at once."
        exit
      rescue Aws::ECS::Errors::NoUpdateAvailableException
        puts "No update needed for #{ci}."
      end
    end
  end

  # Rebuild the slow parts we hope to not have to build frequently like
  # installing packages, gems, and precompiling assets.
  def clear_cache!(repo_name)
    _run("docker image rm #{repo_name}:latest--pre-cache")
    #_run("docker image rm #{repo_url}:latest--pre-cache")

    result = ecr.batch_delete_image({
      image_ids: [
        {
          image_tag: "latest--pre-cache",
        },
      ],
      repository_name: repo_name,
    })

    puts result.to_h.ai
  end

  private

  def _run(c, abort_on_error: false)
    cmd = c.gsub(/\n/, ' ').squeeze(' ')
    puts "Running #{cmd}"

    system(cmd)

    if $CHILD_STATUS.exitstatus != 0 && abort_on_error
      raise "Aborting due to command error"
    end
  end

  define_method(:ecs) { Aws::ECS::Client.new(profile: ENV.fetch('AWS_PROFILE') ) }
  define_method(:ecr) { Aws::ECR::Client.new(profile: ENV.fetch('AWS_PROFILE') ) }
end
