// Generated by CoffeeScript 1.6.3
(function() {
  define(["jquery", "router"], function($, Router) {
    var App;
    App = (function() {
      function App() {
        window.app = this;
        this.router = new Router;
        this.loading_indicator = "&nbsp;&nbsp;&#8635;&nbsp;&nbsp;";
        this.pusher = new Pusher(pkey);
        this.set_button_state = function(el, loading) {
          var $el;
          if (loading == null) {
            loading = true;
          }
          $el = $(el);
          if (loading) {
            $el.data('text', $el.html());
            return $el.attr("disabled", true).html(this.loading_indicator);
          } else {
            return $el.removeAttr("disabled").html($el.data("text"));
          }
        };
        $(document).ajaxError(function(event, jqXHR, ajaxSettings, thrownError) {
          if (jqXHR.status === 422) {
            return alert("You need to sign in to complete this action");
          }
        });
        Backbone.history.start({
          pushState: true
        });
        $("a.toggle").on("click", function(e) {
          e.preventDefault();
          return $("nav" + e.currentTarget.id).toggleClass("open");
        });
      }

      return App;

    })();
    return App;
  });

}).call(this);
