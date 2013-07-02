define [

  "backbone",
  
], (Backbone) ->
  
  "use strict"
  
  class Proposal extends Backbone.Model
    
    url: ->
      if @get("id")
        "/proposals/#{@get("id")}"
      else
        "/proposals"  
        
    voting_time_to_human: ->
      left= Math.round(new Date(@get('finished_at')) - new Date(@get('started_at'))) / 1000
      # less than a hour
      if left <= 3600
        "#{left / 60} minutes left"
      # less than a day  
      else if left <= 86400
        "#{left / 3600} hours left"
      else
        "#{left / 86400} days left"    
    
  Proposal  