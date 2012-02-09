module ApplicationHelper
  ActionView::Base.default_form_builder = SapphireFormBuilder
  
  def nav_button(str, img, href)
    button = "<button class='button'>#{image_tag(img) } #{str}</button>".html_safe
    link_to(button, href)
  end
  
end
