class SapphireFormBuilder < ActionView::Helpers::FormBuilder
    
  def text_field(attribute, options={})
    options[:class] = ([options[:class]].flatten << "text_field").join(' ')
    lab = options.delete(:label) || attribute
    label(lab) + super
  end

  def select(attribute, opts_for_select, options={})
    options[:class] = ([options[:class]].flatten << "select").join(' ')
    lab = options.delete(:label) || attribute
    label(lab) + super(attribute, opts_for_select, options)
  end
  
  def label(attribute, options={})
    "<label class='label'>#{attribute}</label>".html_safe
  end

  def text_area(attribute, options={})
    options[:class] = ([options[:class]].flatten << "text_area").join(' ')
    options[:rows] = 4
    lab = options.delete(:label) || attribute
    label(lab) + super
  end

  def submit(attribute, options={})
    options[:class] = ([options[:class]].flatten << "button").join(' ')
    attribute = options.delete(:submit_image).to_s + attribute
    cancel = options.delete(:cancel_link)
    @template.content_tag(:button, attribute, options) + 
      (cancel ? "<span class='text_button_padding'> or </span>#{cancel}".html_safe : "")
  end

end