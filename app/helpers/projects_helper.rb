module ProjectsHelper

  def users_for_select(project)
    users = User.all - project.memberships.users
    users.map{|u| ["#{u.last_name}, #{u.first_name}",u.id] }
  end

end
