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

toggle = function() {
  var ele = document.getElementById("current_schema");
  var text = document.getElementById("displayText");
  if(ele.style.display == "block") {
    ele.style.display = "none";
    text.innerHTML = "<img src='/images/web-app-theme/icons/add.png' height='16px'></img>";
  } else {
    ele.style.display = "block";
    text.innerHTML = "<img src='/images/web-app-theme/icons/delete.png' height='16px'></img>";
  }
} 