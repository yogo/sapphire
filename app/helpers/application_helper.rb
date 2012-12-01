module ApplicationHelper
  ActionView::Base.default_form_builder = SapphireFormBuilder
  
  def nav_button(str, img, href, method=nil)
    button = "<button class='button'>#{image_tag(img) } #{str}</button>".html_safe
    if href =~ /onclick/i
      "<span #{href}>#{button}</span>".html_safe
    else
      link_to(button, href, :method=>method) + "&nbsp;".html_safe
    end
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

  def alert_type(t)
    case t
    when :notice, :info                   then 'alert-info'
    when :error, :warning, :fail, :alert  then 'alert-error'
    when :success                         then 'alert-success'
    else ''
    end
  end

  def ajax_modal_js(target, path, full_width=nil)
    m = full_width ? 'fwmodal' : 'modal'
    <<-MODAL
      var $modal = $('#ajax-modal');
      var $fwmodal = $('#ajax-modal-fw');
      $('#{target}').on('click', function(){
        $('body').modalmanager('loading');
        setTimeout(function(){
          $#{m}.load('#{path}', '', function(){
            $#{m}.modal();
          });
        }, 1000);
      });
    MODAL
  end

end
