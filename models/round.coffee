App      = require('../app')
state    = require('state')
debug    = require('debug')('werewolves:model:round')
_        = require('underscore')
Backbone = require('backbone')
Models   = App.module "Models"
State    = App.module "State"


class Models.Action extends Models.BaseModel
  urlRoot: 'action'
  @attribute 'action'
  @attribute 'target'
  initialize: ->
    super
    @publish()

  # only sync actions to the same roles
  filterData: (session, event) ->
    # always see lynchings, even for observers
    return null if @action == 'lynch'

    # always block other events, so you cant just
    # open a spare tab to see the killings.
    player = State.getPlayer(session.id)
    return true unless player

    # only pass the event back when it is the same
    # role.
    @action != player.voteAction()

class Models.Actions extends Models.BaseCollection
  url: 'action'
  model: Models.Action

class Models.Round extends Models.BaseModel
  urlRoot: 'round'
  @attribute 'death'
  @attribute 'phase'
  @attribute 'number'
  @attribute 'activeTotal'
  initialize: (data = {}, opts = {}) ->
    @timer = State.getTimer()
    @id = data.id or App.ns.uuid()
    @players ?= opts.players
    @actions = new Models.Actions []
    @actions.reset data.actions if data.actions
    @timer.limit = @activeTotal * 30000
    super
    @state().change(data._state or 'votes.none')
    @publish()
    @trigger('state', @state().path())

    @listenTo @timer, 'end', @endPhase

  destroy: ->
    @stopListening @timer
    @off()

    super
    delete @players

    @actions.destroy()

  voteState: ->
    @go('votes.none')
    @go('votes.some')
    @go('votes.all')

  toJSON: (session) ->
    obj = super
    obj.actions = @actions.toJSON(session)
    obj

  endPhase: ->
    @go('complete.died')
    @go('complete.survived')

  initState: -> state @,
    votes: state 'abstract',
      admit:
          'complete.*': false

      # waiting for the first vote to be cast
      none: state 'default',
        admit:
          '*': ->
            return true if !App.server
            !@owner.actions.length
        arrive: ->
          @timer.start()

      # we have  votes
      some:
        admit:
          'none': ->
            return true if !App.server
            (1 <= @owner.actions.length <= @owner.activeTotal)

      # we have all the votes
      all:
        enter: ->
          if @timer.remaining() >= 30000
            @timer.limit = 30000
            @timer.reset()
        admit:
          'some': ->
            return true if !App.server
            @owner.actions.length == @owner.activeTotal

    complete: state 'conclusive',
      enter: ->
        return true if !App.server
        @getDream()
        @death = @getDeath()

      # there is a death
      died: state 'final',
        admit:
          'votes.*': ->
            return true if !App.server
            !!@owner.getDeath()
          'complete.*': false

      # there wasn't one
      survived: state 'final',
        admit:
          'votes.*': ->
            return true if !App.server
            !@owner.getDeath()
          'complete.*': false


  # All active players who have not voted vote for themselves.
  #
  # In effect this is to help with people timing out.
  #
  # If the wolf doesn't pick someone to vote for they will
  # vote themselves out of the game.
  padVotes: ->
    filterFn = (p) -> p.voteAction()
    mapFn = (p) =>
      existing = @actions.get(p.id)
      return existing if existing

      result =
        id: p.id
        action: p.voteAction()
        target: p.id

    @players.chain()
      .filter(filterFn)
      .map(mapFn)
      .value()

  # transform an array of actions into a single
  # array of votes (player id only), indexed
  # by who they voted for
  getVotes: ->
    action = if @phase is 'day' then 'lynch' else 'eat'
    byTarget      = (a)    -> a.target
    sortByLength  = (a)    -> -a.votes?.length
    makeArray     = (v, k) ->
      id: k,
      votes: _(v).pluck('id')

    _(@_getActions()).chain()
      .where(action: action)
      .groupBy(byTarget)
      .map(makeArray)
      .sortBy(sortByLength)
      .value()

  # separate function to override on server
  #
  # allows us to pad the votes only on the server
  _getActions: ->
    @actions.models

  # Do a simple transform on the votes to give us
  # the vote count instead of a list of people who
  # voted for them.
  countVotes: ->
    _(@getVotes()).map (v) ->
      _.extend {}, v, votes: v.votes.length

  # make sure there is only a single victim of the
  # voting / eating process.
  #
  # returns the player id meant to die,
  # otherwise returns false for draws.
  getDeath: () ->
    votes    = @countVotes()
    return false if !votes.length

    victim   =  _(votes).first()
    top      = _(votes).where votes: victim.votes
    return if top.length == 1 then victim.id else false

  getDream: () ->
    seer = @players.findWhere(role: 'seer')
    return false if seer.state().is('dead')

    action = @actions.findWhere(action: 'see')
    return false if !action

    seen = seer.seen or []
    seen.push action.target
    seer.seen = seen


  # Pick a victim to kill.
  choose: (me, target, opts = {}) ->

    # has to have a valid player
    player = State.getPlayer me
    return false if !player

    # has to have a valid action
    actionName = player.voteAction()
    return false if !actionName

    # has to be a valid victim
    victim = State.getPlayer target
    return false if !victim

    # no voting for the dead
    return false if !victim.state().isIn('alive')

    debug 'choose', me, target, actionName

    action = @actions.findWhere
      id:me
      action:actionName
    
    if not action
      action ?=
        id:me
        action:actionName
        target:target

      @actions.add action, opts
    else
      action.set
        target: target

    debug "change vote state", action
    @voteState()

class Models.Rounds extends Models.BaseCollection
  url: 'round'
  model: Models.Round
