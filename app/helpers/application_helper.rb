module ApplicationHelper
  ActionView::Base.default_form_builder = SapphireFormBuilder
  
  def nav_button(str, img, href, method=nil)
    button = "<button class='button'>#{image_tag(img) } #{str}</button>".html_safe
    link_to(button, href, :method=>method)
  end

  def nav_helper
    nav = {}
    if    @nav_my_project
      nav[:my_project] = 'active'
    elsif @nav_public_project
      nav[:public_project] = 'active'
    end
    if    @nav_controlled_vocabulary
      nav[:controlled_vocabulary] = 'active'
    end
    nav
  end
end
