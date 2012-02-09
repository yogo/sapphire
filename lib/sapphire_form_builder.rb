class SapphireFormBuilder < ActionView::Helpers::FormBuilder
    
  def text_field(attribute, options={})
    options[:class] = (options[:class].to_a << "text_field").join(' ')
    lab = options.delete(:label) || attribute
    label(lab) + super
  end

  def label(attribute, options={})
    options[:class] = (options[:class].to_a << "label").join(' ')
    super
  end

  def text_area(attribute, options={})
    options[:class] = (options[:class].to_a << "text_area").join(' ')
    options[:rows] = 4
    lab = options.delete(:label) || attribute
    label(lab) + super
  end

  def submit(attribute, options={})
    options[:class] = (options[:class].to_a << "button").join(' ')
    attribute = options.delete(:submit_image) + attribute
    cancel = options.delete(:cancel_link)
    @template.content_tag(:button, attribute, options) + 
      (cancel ? "<span class='text_button_padding'> or </span>#{cancel}".html_safe : "")
  end

end