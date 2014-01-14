(function() {
  $(function() {
    $(".animated-when-visible").each(function(i, el) {
      el = $(el);
      if (el.visible(true)) {
        return el.addClass("animated " + el.data("animation-type"));
      }
    });
    $(".animated-when-hover").hover(function() {
      $(this).addClass("animated " + $(this).data("animation-type"));
    }, function() {
      $(this).removeClass("animated " + $(this).data("animation-type"));
    });
    $(window).scroll(function(event) {
      return $(".animated-when-visible").each(function(i, el) {
        el = $(el);
        if (el.visible(true)) {
          return el.addClass("animated " + el.data("animation-type"));
        }
      });
    });
    $(".dial").knob({
      readOnly: true,
      draw: function() {
        return $(this.i).val(this.cv + "%");
      }
    });
    $.scrollUp({
      scrollText: "<i class='icon-chevron-up'></i>"
    });
    $(".isotope-w").isotope({
      itemSelector: '.item',
      layoutMode: 'fitRows'
    });
    return $(".portfolio-filters a").click(function() {
      var selector;
      selector = $(this).attr("data-filter");
      $(".isotope-w").isotope({
        filter: selector
      });
      return false;
    });
  });

  $('audio').animate({volume: 0}, 1);
  $('audio').on('play', function() {
      $(this).animate({volume: 1}, 1000);
  });
  $('audio').on('pause', function(e) {
      var $this = $(this);
      $this.animate({volume: 0}, 1000);
  });

  hljs.tabReplace = '    ';
  hljs.initHighlightingOnLoad();  
}).call(this);
