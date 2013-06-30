// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["jquery", "underscore", "backbone", "collections/proposals", "views/proposal"], function($, _, Backbone, Proposals, ProposalView) {
    "use strict";
    var ProposalsView, _ref;
    ProposalsView = (function(_super) {
      __extends(ProposalsView, _super);

      function ProposalsView() {
        _ref = ProposalsView.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      ProposalsView.prototype.el = "ul.collection";

      ProposalsView.prototype.initialize = function(options) {
        var _this = this;
        this.collection = new Proposals;
        this.collection.on("reset", this.render, this);
        this.collection.on("add", this.addProposal, this);
        this.collection.fetch();
        this.channel = app.pusher.subscribe("proposals");
        this.channel.bind('create', function(data) {
          return _this.collection.add(data);
        });
        return this;
      };

      ProposalsView.prototype.render = function() {
        var proposal;
        for (proposal in this.collection.models) {
          addProposal(proposal);
        }
        return this;
      };

      ProposalsView.prototype.addProposal = function(proposal) {
        var view;
        view = new ProposalView({
          model: proposal
        });
        return this.$el.append(view.render().el);
      };

      return ProposalsView;

    })(Backbone.View);
    return ProposalsView;
  });

}).call(this);
