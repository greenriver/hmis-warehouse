require 'test_helper'

class EntityViewabilityTest < ActiveSupport::TestCase

  FIXTURE = {
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
    assert_equal [p.organization], prep(organizations.viewable_by(u)), "only the one organization is viewable"
    assert_equal [p.data_source], prep(datasources.viewable_by(u)), "only the one data source is viewable"
  end

  def test_when_user_assigned_organization
    u = get :users, :u1
    o = get :organizations, :o1
    u.add_viewable o
    assert_equal prep(o.projects), prep(projects.viewable_by(u)), "all the projects under org are viewable"
    assert_equal [o], prep(organizations.viewable_by(u)), "only the one organization is viewable"
    assert_equal [o.data_source], prep(datasources.viewable_by(u)), "only the one data source is viewable"
  end

  def test_when_user_assigned_datasource
    u = get :users, :u1
    ds = get :data_sources, :ds1
    u.add_viewable ds
    assert_equal prep(ds.projects), prep(projects.viewable_by(u)), "all the projects under datasource are viewable"
    assert_equal prep(ds.organizations), prep(organizations.viewable_by(u)), "all the organizations under the data source are viewable"
    assert_equal [ds], prep(datasources.viewable_by(u)), "only the one data source is viewable"
  end

  def test_all_viewable_role
    u = get :users, :u1
    r = get :roles, :r1
    r.update_column :can_edit_anything_super_user, true
    u.roles << r
    u.save
    assert_equal prep( all :projects ), prep( projects.viewable_by u ), "panopticon user can see all projects"
    assert_equal prep( all :organizations ), prep( organizations.viewable_by u ), "panopticon user can see all organizations"
    assert_equal prep( all :data_sources ), prep( datasources.viewable_by u ), "panopticon user can see all data sources"
  end

  def test_two_projects_same_organization
    u = get :users, :u1
    p1 = get :projects, :p1
    p2 = get :projects, :p2
    u.add_viewable p1, p2
    assert_equal prep([ p1, p2 ]), prep( projects.viewable_by u ), "can see both projects"
    assert_equal prep([ p1.organization, p2.organization ]), prep( organizations.viewable_by u ), "can see projects' organizations"
    assert_equal prep([ p1.data_source, p2.data_source ]), prep( datasources.viewable_by u ), "can see projects' data sources"
  end

 def test_two_projects_different_organizations
    u = get :users, :u1
    p1 = get :projects, :p1
    p2 = get :projects, :p4
    u.add_viewable p1, p2
    assert_equal prep([ p1, p2 ]), prep( projects.viewable_by u ), "can see both projects"
    assert_equal prep([ p1.organization, p2.organization ]), prep( organizations.viewable_by u ), "can see projects' organizations"
    assert_equal prep([ p1.data_source, p2.data_source ]), prep( datasources.viewable_by u ), "can see projects' data sources"
  end

 def test_two_projects_different_data_sources
    u = get :users, :u1
    p1 = get :projects, :p1
    p2 = get :projects, :p7
    u.add_viewable p1, p2
    assert_equal prep([ p1, p2 ]), prep( projects.viewable_by u ), "can see both projects"
    assert_equal prep([ p1.organization, p2.organization ]), prep( organizations.viewable_by u ), "can see projects' organizations"
    assert_equal prep([ p1.data_source, p2.data_source ]), prep( datasources.viewable_by u ), "can see projects' data sources"
  end

  def test_two_organizations_same_data_source
    u = get :users, :u1
    o1 = get :organizations, :o1
    o2 = get :organizations, :o2
    u.add_viewable o1, o2
    assert_equal prep( o1.projects + o2.projects ), prep( projects.viewable_by u ), "can see all projects of both organizations"
    assert_equal prep([ o1, o2 ]), prep( organizations.viewable_by u ), "can see both organizations"
    assert_equal prep([ o1.data_source, o2.data_source ]), prep( datasources.viewable_by u ), "can see organizations' data sources"
  end

  def test_two_organizations_different_data_sources
    u = get :users, :u1
    o1 = get :organizations, :o1
    o2 = get :organizations, :o3
    u.add_viewable o1, o2
    assert_equal prep( o1.projects + o2.projects ), prep( projects.viewable_by u ), "can see all projects of both organizations"
    assert_equal prep([ o1, o2 ]), prep( organizations.viewable_by u ), "can see both organizations"
    assert_equal prep([ o1.data_source, o2.data_source ]), prep( datasources.viewable_by u ), "can see organizations' data sources"
  end

  def test_organization_and_one_of_its_projects
    u = get :users, :u1
    o = get :organizations, :o1
    p = get :projects, :p1
    u.add_viewable o, p
    assert_equal prep( o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep([ o, p.organization ]), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_organization_and_project_different_org_same_ds
    u = get :users, :u1
    o = get :organizations, :o1
    p = get :projects, :p4
    u.add_viewable o, p
    assert_equal prep( o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep([ o, p.organization ]), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_organization_and_project_different_org_different_ds
    u = get :users, :u1
    o = get :organizations, :o1
    p = get :projects, :p7
    u.add_viewable o, p
    assert_equal prep( o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep([ o, p.organization ]), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_data_source_and_org
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o1
    u.add_viewable ds, o
    assert_equal prep( ds.projects + o.projects ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [o] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_data_source_and_org_different_ds
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o3
    u.add_viewable ds, o
    assert_equal prep( ds.projects + o.projects ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [o] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_data_source_and_project
    u = get :users, :u1
    ds = get :data_sources, :ds1
    p = get :projects, :p1
    u.add_viewable ds, p
    assert_equal prep( ds.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_data_source_and_project_different_ds
    u = get :users, :u1
    ds = get :data_sources, :ds1
    p = get :projects, :p7
    u.add_viewable ds, p
    assert_equal prep( ds.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_ds_o_p_1
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o1
    p = get :projects, :p1
    u.add_viewable ds, o, p
    assert_equal prep( ds.projects + o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [ o, p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_ds_o_p_2
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o1
    p = get :projects, :p4
    u.add_viewable ds, o, p
    assert_equal prep( ds.projects + o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [ o, p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_ds_o_p_3
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o3
    p = get :projects, :p7
    u.add_viewable ds, o, p
    assert_equal prep( ds.projects + o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [ o, p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_ds_o_p_4
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o3
    p = get :projects, :p10
    u.add_viewable ds, o, p
    assert_equal prep( ds.projects + o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [ o, p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_ds_o_p_5
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o3
    p = get :projects, :p1
    u.add_viewable ds, o, p
    assert_equal prep( ds.projects + o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [ o, p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  def test_ds_o_p_6
    u = get :users, :u1
    ds = get :data_sources, :ds1
    o = get :organizations, :o3
    p = get :projects, :p4
    u.add_viewable ds, o, p
    assert_equal prep( ds.projects + o.projects + [p] ), prep( projects.viewable_by u ), "can see correct projects"
    assert_equal prep( ds.organizations + [ o, p.organization] ), prep( organizations.viewable_by u ), "can see correct organizations"
    assert_equal prep([ ds, o.data_source, p.data_source ]), prep( datasources.viewable_by u ), "can see correct data sources"
  end

  ## fixturish stuff below this point

  # because this seem(ed) simpler than a fixture file
  MODELS = {}
  setup do
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
      FIXTURE.each do |type, h|
        recursive_create.call type, h
      end
    end
  end

  def get(model, id)
    MODELS[model][id]
  end

  def all(model)
    MODELS.fetch( model, {} ).values
  end

  def prep(relation)
    relation.to_a.compact.uniq.sort_by(&:id) rescue byebug
  end

  teardown do
    MODELS.fetch( :users, {} ).values.each do |u|
      GrdaWarehouse::Hud::UserViewableEntity.where( user_id: u.id ).delete_all
      u.really_delete
    end
    MODELS.delete :users
    %i( roles projects organizations data_sources ).each do |type|
      instances = ( MODELS.fetch type, {} ).values
      if instances.present?
        if instances.first.respond_to?(:really_delete)
          instances.each(&:really_delete)
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
