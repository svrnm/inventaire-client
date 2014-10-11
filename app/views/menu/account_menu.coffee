module.exports = class AccountMenu extends Backbone.Marionette.ItemView
  template: require 'views/menu/templates/account_menu'
  events:
    'click #edit, #pic': -> app.execute 'show:user:edit'
    'click #logout': -> app.execute 'persona:logout'

  onShow: -> app.execute 'foundation:reload'
  serializeData: ->
    attrs =
      search:
        nameBase: 'search'
        field: {}
        button:
          icon: 'search'
          classes: 'secondary'
    return _.extend attrs, @model.toJSON()