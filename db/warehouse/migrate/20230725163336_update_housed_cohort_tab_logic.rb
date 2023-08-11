class UpdateHousedCohortTabLogic < ActiveRecord::Migration[6.1]
  def up
    rules = {
      'operator' => 'and',
      'left' => {
        'column' => 'housed_date',
        'operator' => '<>',
          'value' => nil,
        },
        'right' => {
          'operator' => 'or',
          'left' => {
            'column' => 'destination',
            'operator' => '<>',
            'value' => nil,
          },
          'right' => {
            'column' => 'destination',
            'operator' => '<>',
            'value' => '',
          },
        },
      }
    name = 'Housed'
    GrdaWarehouse::CohortTab.where(name: name, rules: rules).update_all(rules: GrdaWarehouse::CohortTab.default_rules.detect{ |r| r[:name] == name }[:rules])

    rules = {
      'operator' => 'and',
      'left' => {
        'operator' => 'and',
          'left' => {
            'operator' => 'or',
            'left' => {
              'operator' => 'or',
              'left' => {
                'column' => 'destination',
                'operator' => '==',
                'value' => nil,
              },
              'right' => {
                'column' => 'destination',
                'operator' => '==',
                'value' => '',
              },
            },
            'right' => {
              'column' => 'housed_date',
            'operator' => '==',
            'value' => nil,
          },
        },
        'right' => {
          'operator' => 'or',
          'left' => {
            'column' => 'ineligible',
            'operator' => '==',
            'value' => nil,
          },
          'right' => {
            'column' => 'ineligible',
            'operator' => '==',
            'value' => false,
          },
        },
      },
      'right' => {
        'column' => 'active',
        'operator' => '==',
        'value' => true,
      },
    }
    name = 'Active Clients'
    GrdaWarehouse::CohortTab.where(name: name, rules: rules).update_all(rules: GrdaWarehouse::CohortTab.default_rules.detect{ |r| r[:name] == name }[:rules])

    rules = {
      'operator' => 'and',
      'left' => {
        'column' => 'ineligible',
        'operator' => '==',
        'value' => true,
      },
      'right' => {
        'operator' => 'or',
        'left' => {
          'column' => 'housed_date',
          'operator' => '==',
            'value' => nil,
          },
          'right' => {
            'operator' => 'or',
            'left' => {
              'column' => 'destination',
              'operator' => '==',
              'value' => nil,
            },
            'right' => {
              'column' => 'destination',
              'operator' => '==',
              'value' => '',
            },
          },
        },
      }
    name = 'Ineligible'
    GrdaWarehouse::CohortTab.where(name: name, rules: rules).update_all(rules: GrdaWarehouse::CohortTab.default_rules.detect{ |r| r[:name] == name }[:rules])
  end
end
