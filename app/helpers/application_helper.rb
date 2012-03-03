module ApplicationHelper
  ActionView::Base.default_form_builder = SapphireFormBuilder
  
  def nav_button(str, img, href, method=nil)
    button = "<button class='button'>#{image_tag(img) } #{str}</button>".html_safe
    link_to(button, href, :method=>method)
  end

  def my_project?(project, response = '')
    if project && project.members.include?(current_user)
      return response
    end
    return ''
  end
  
  def public_project?(project, response = '')
    if project && project.public?
      return response
    end
    return ''
  end
end
