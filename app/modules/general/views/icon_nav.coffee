module.exports = Marionette.ItemView.extend
  template: require './templates/icon_nav'
  className: 'innerIconNav'
  events:
    'click .search': 'showSearch'
    'click .user': 'showDashboard'
    'click .friends': 'showFriends'
    'click .settings': 'showSettings'

  ui:
    all: 'a.iconButton'
    search: '.search'
    user: '.user'
    friends: '.friends'
    settings: '.settings'

  onShow: ->
    # app.commands.setHandler 'icon:nav:selected', @selectButton.bind(@)
    @selectButtonFromRoute location.pathname.slice(1)
    @listenTo app.vent, 'route:navigate', @selectButtonFromRoute.bind(@)

  selectButtonFromRoute: (route)->
    root = route.split('/')[0]
    switch root
      when 'dashboard' then @selectButton 'user'
      when 'inventory' then @selectButton 'friends'
      when 'settings' then @selectButton 'settings'

  selectButton: (uiName)->
    @ui.all.removeClass 'selected'
    @ui[uiName].addClass 'selected'

  showSearch: ->
    @selectButton 'search'
    app.execute 'show:search'

  showDashboard: ->
    @selectButton 'user'
    app.execute 'show:dashboard'

  showFriends: ->
    @selectButton 'friends'
    app.execute 'show:inventory:general'

  showSettings: ->
    @selectButton 'settings'
    app.execute 'show:settings:profile'