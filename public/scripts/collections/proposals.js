// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["backbone", "models/proposal"], function(Backbone, Proposal) {
    "use strict";
    var Proposals, _ref;
    Proposals = (function(_super) {
      __extends(Proposals, _super);

      function Proposals() {
        _ref = Proposals.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Proposals.prototype.model = Proposal;

      Proposals.prototype.url = "/proposals";

      Proposals.prototype.parse = function(response) {
        this.pagination = {
          page: response.page,
          total: response.total_page
        };
        return response.models;
      };

      return Proposals;

    })(Backbone.Collection);
    return Proposals;
  });

}).call(this);