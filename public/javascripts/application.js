// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

  changeTab = function(tab, coll) {
    // set tabs to inactive
    $(".block .secondary-navigation li").removeClass('active');
    // hide all section
    $(".block .collection").hide();
    // activate the new tab
    $(".block .secondary-navigation " + tab).addClass('active');
    // show the section
    $(".block " + coll).show();
  };