module ApplicationHelper
  ActionView::Base.default_form_builder = SapphireFormBuilder
  
  def nav_button(str, img, href, method="get")
    button = "<button class='button'>#{image_tag(img) } #{str}</button>".html_safe
    link_to(button, href, :method=>method.to_sym)
  end
  
end
