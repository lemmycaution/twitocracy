#global require

"use strict"

require.config

  shim:
    
    underscore:
      exports: "_"

    backbone:
      deps: ["underscore", "jquery"]
      exports: "Backbone"

  paths:
    jquery: "/scripts/vendor/jquery.min"
    backbone: "/scripts/vendor/backbone-min"
    underscore: "/scripts/vendor/underscore-min"

require [
 "underscore",
 "app"
], (_, App) ->
  
  _.serializeForm = (form) ->
    iter = (memo,obj) -> 
      memo[obj.name] = obj.value
      memo
    _.reduce($(form).serializeArray(), iter, {})
  
  $(document).ready (e) ->
    
    window.app = new App
    
  