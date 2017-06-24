require 'test_helper'

class EntityViewabilityTest < ActiveSupport::TestCase

  def test_initially_user_can_see_nothing
    u = get :users, :u1
    assert u, "we have a user"
    assert u.data_sources.empty?, 'no data sources'
    assert u.organizations.empty?, 'no organizations'
    assert u.projects.empty?, 'no projects'
    assert_not datasources.viewable_by(u).exists?, 'data source viewable by gives us nothing'
    assert_not organizations.viewable_by(u).exists?, 'org viewable by gives us nothing'
    assert_not projects.viewable_by(u).exists?, 'project viewable by gives us nothing'
  end

  def test_when_user_assigned_project
    u = get :users, :u1
    p = get :projects, :p1
    u.add_viewable p
    assert_equal [p], projects.viewable_by(u).all, "only the one project is viewable"
    assert_equal [p.data_source], datasources.viewable_by(u), "only the one data source is viewable"
    assert_equal [p.organization], organizations.viewable_by(u), "only the one organization is viewable"
  end

  def test_when_user_assigned_organization
    u = get :users, :u1
    o = get :organizations, :o1
    u.add_viewable o
    assert_equal o.projects.to_a, projects.viewable_by(u).all, "all the projects under org are viewable"
    assert_equal [o.data_source], datasources.viewable_by(u), "only the one data source is viewable"
    assert_equal [o], organizations.viewable_by(u), "only the one organization is viewable"
  end

  ## fixturish stuff below this point

  # because this seem(ed) simpler than a fixture file
  MODELS = {}
  setup do
    data = {
      data_sources: {
        ds1: {
          organizations: {
            o1: {
              projects: %i[ p1 p2 p3 ]
            },
            o2: {
              projects: %i[ p4 p5 p6 ]
            }
          }
        },
        ds2: {
          organizations: {
            o3: {
              projects: %i[ p7 p8 p9 ]
            },
            o4: {
              projects: %i[ p10 p11 p12 ]
            }
          }
        }
      },
      users: %i[ u1 ],
      roles: %i[ r1 ]
    }
    # some rigamarole so we can keep a nice declarative fixture
    uid = SecureRandom.uuid   # suspenders for our belt
    id = 1
    get_id = -> () { i = id; id +=1; i }
    recursive_create = -> (type, h, parent=nil) do
      case type
      when :data_sources
        h.each do |name, sub_h|
          ds = GrdaWarehouse::DataSource.new name: "#{name} #{uid}", short_name: name
          ds.save validate: false
          ( MODELS[:data_sources] ||= {} )[name] = ds
          recursive_create.call *(sub_h.to_a.first), ds
        end
      when :organizations
        h.each do |name, sub_h|
          org = GrdaWarehouse::Hud::Organization.new name: "#{name} #{uid}", data_source_id: parent.id, OrganizationID: get_id.()
          org.save validate: false
          ( MODELS[:organizations] ||= {} )[name] = org
          recursive_create.call *(sub_h.to_a.first), org
        end
      when :projects
        h.each do |name|
          proj = GrdaWarehouse::Hud::Project.new name: "#{name} #{uid}", data_source_id: parent.data_source_id, OrganizationID: parent.OrganizationID, ProjectID: get_id.()
          proj.save validate: false
          ( MODELS[:projects] ||= {} )[name] = proj
        end
      when :users
        domain = "my#{ uid.tr '-', '' }.com"
        h.each do |name|
          User.connection.execute <<-SQL
            INSERT INTO #{User.quoted_table_name}
              (first_name, last_name, email, created_at, updated_at)
              VALUES
              ('#{name}','#{uid}','#{name}@#{domain}','#{DateTime.current.to_default_s}','#{DateTime.current.to_default_s}')
          SQL
          user = User.where( first_name: name, last_name: uid ).first
          ( MODELS[:users] ||= {} )[name] = user
        end
      when :roles
        h.each do |name|
          role = Role.create! name: "#{name} #{uid}"
          ( MODELS[:roles] ||= {} )[name] = role
        end
      else
        raise "something has gone very wrong"
      end
    end
    User.transaction do
      data.each do |type, h|
        recursive_create.call type, h
      end
    end
  end

  def get(model, id)
    MODELS[model][id]
  end

  teardown do
    MODELS.fetch( :users, {} ).values.each do |u|
      GrdaWarehouse::Hud::UserViewableEntity.where( user_id: u.id ).destroy_all
      u.really_destroy!
    end
    %i( roles projects organizations data_sources ).each do |type|
      instances = ( MODELS.fetch type, {} ).values
      if instances.present?
        if instances.first.respond_to?(:really_destroy!)
          instances.each(&:really_destroy!)
        else
          instances.each(&:delete)
        end
      end
      MODELS.delete type
    end
  end

  def organizations
    GrdaWarehouse::Hud::Organization
  end

  def projects
    GrdaWarehouse::Hud::Project
  end

  def datasources
    GrdaWarehouse::DataSource
  end
end
