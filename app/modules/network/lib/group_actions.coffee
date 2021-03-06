error_ = require 'lib/error'

module.exports =
  inviteUser: (user)->
    @action 'invite', user.id
    .then @updateInvited.bind(@, user)
    # let views catch the error

  updateInvited: (user)->
    @push 'invited',
      user: user.id
      invitor: app.user.id
      timestamp: _.now()
    user.trigger 'group:invite'

  acceptInvitation: ->
    @moveMembership app.user, 'invited', 'members'

    @action 'accept'
    .then @fetchGroupUsersMissingItems.bind(@)
    .catch @revertMove.bind(@, app.user, 'invited', 'members')

  declineInvitation: ->
    @moveMembership app.user, 'invited', 'declined'

    @action 'decline'
    .catch @revertMove.bind(@, app.user, 'invited', 'declined')

  requestToJoin: ->
    @createRequest()

    @action 'request'
    .catch @revertMove.bind(@, app.user, null, 'requested')

  createRequest: ->
    @push 'requested',
      user: app.user.id
      timestamp: _.now()

  cancelRequest: ->
    @moveMembership app.user, 'requested', 'tmp'
    @action 'cancel-request'
    .catch @revertMove.bind(@, app.user, 'requested', 'tmp')

  acceptRequest: (user)->
    @moveMembership user, 'requested', 'members'
    @action 'accept-request', user.id
    .catch @revertMove.bind(@, user, 'requested', 'members')

  refuseRequest: (user)->
    @moveMembership user, 'requested', 'tmp'
    @action 'refuse-request', user.id
    .catch @revertMove.bind(@, user, 'requested', 'tmp')

  makeAdmin: (user)->
    @moveMembership user, 'members', 'admins'
    @action 'make-admin', user.id
    .catch @revertMove.bind(@, user, 'members', 'admins')

  kick: (user)->
    @moveMembership user, 'members', 'tmp'
    @action 'kick', user.id
    .catch @revertMove.bind(@, user, 'members', 'tmp')

  leave: ->
    initialCategory = if @mainUserIsAdmin() then 'admins' else 'members'
    @moveMembership app.user, initialCategory, 'tmp'
    @action 'leave'
    .catch @revertMove.bind(@, app.user, initialCategory, 'tmp')

  action: (action, userId)->
    _.preq.put app.API.groups.private,
      action: action
      group: @id
      # requiered only for actions implying an other user
      user: userId
    .then _.Tap(@_postActionHooks.bind(@, action))

  _postActionHooks: (action)->
    app.execute 'track:group', action
    @trigger "action:#{action}"

  revertMove: (user, previousCategory, newCategory, err)->
    @moveMembership user, newCategory, previousCategory
    throw err

  # moving membership object from previousCategory to newCategory
  moveMembership: (user, previousCategory, newCategory)->
    membership = @findMembership previousCategory, user
    unless membership? then throw error_.new 'membership not found', arguments

    @without previousCategory, membership
    # let the possibility to just destroy the doc
    # by letting newCategory undefined
    if newCategory? then @push newCategory, membership

    if app.request 'user:isMainUser', user.id
      app.vent.trigger 'group:main:user:move'
