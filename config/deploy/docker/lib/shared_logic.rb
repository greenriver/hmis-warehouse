module SharedLogic
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-strategies.html
  def _placement_strategy
    [
      {
        # Distribute across zones first
        'field': 'attribute:ecs.availability-zone',
        'type': 'spread',
      },
      {
        # Distribute across instances
        'field': 'instanceId',
        'type': 'spread',
      },
      {
        # Then try to maximize utilization (minimize number of EC2 instances)
        'field': 'memory',
        'type': 'binpack',
      },
    ]
  end

  def _placement_constraints
    [
      {
        'type': 'distinctInstance',
      },
    ]
  end
end
