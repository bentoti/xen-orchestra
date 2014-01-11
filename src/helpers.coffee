$_ = require 'underscore'

#=====================================================================

$asArray = (val) -> if $_.isArray val then val else [val]
$asFunction = (val) -> if $_.isFunction val then val else -> val

$removeValue = (array, value) ->
  index = array.indexOf value
  return false if index is -1
  array.splice index, 1
  true

#---------------------------------------------------------------------

# TODO: currently the watch can be updated multiple times per
# “$MappedCollection2.set()” which is inefficient: there should be
# possible to address that.

$watch = (collection, {
  # Key(s) of the “remote” objects watched.
  #
  # If it is a function, it is evaluated in the scope of the “current”
  # object. (TODO)
  #
  # Default: undefined
  keys

  # Alias for `keys`.
  key

  # Rule(s) of the “remote” objects watched.
  #
  # If it is a function, it is evaluated in the scope of the “current”
  # object. (TODO)
  #
  # Note: `key`/`keys` and `rule`/`rules` cannot be used both.
  #
  # Default: undefined
  rules

  # Alias for `rules`.
  rule

  # Value to add to the set.
  #
  # If it is a function, it is evaluated in the scope of the “remote”
  # object.
  #
  # Default: -> @val
  val

  # Predicates the “remote” object must fulfill to be used.
  #
  # Default: -> true
  if: cond

  # Function evaluated in the scope of the “remote” object which
  # returns the key of the object to update (usually the current one).
  #
  # TODO: Does it make sense to return an array?
  #
  # Default: undefined
  bind

  # Initial value.
  init
}, fn) ->
  val = if val is undefined
    # The default value is simply the value of the item.
    -> @val
  else
    $asFunction val

  watcher = {
    # Method allowing the cleanup when the helper is no longer used.
    cleanUp: -> # TODO: noop for now.

    # Keys of items using the current helper.
    consumers: Object.create null

    generator: ->
      {key} = this

      # Register this item has a consumer.
      watcher.consumers[@key] = true

      # Returns the value for this item if any or the common value.
      values = watcher.values
      namespace = "$#{key}"
      if namespace of values
        values[namespace]
      else
        values.common

    # Current values.
    values: Object.create null
  }
  watcher.values.common = init

  process = (event, items) ->
    # Values are grouped by namespace.
    valuesByNamespace = Object.create null

    $_.each items, (item) ->
      return unless not cond? or cond.call item

      if bind?
        key = bind.call item

        # If bind did return a key, ignores this value.
        return unless key?

        namespace = "$#{key}"
      else
        namespace = 'common'

      # Computes the current value.
      value = val.call item

      (valuesByNamespace[namespace] ?= []).push value

    # For each namespace.
    for namespace, values of valuesByNamespace

      # Updates the value.
      value = watcher.values[namespace]
      ctx = {
        value: if value is undefined then init else value
      }
      changed = if event is 'enter'
        fn.call ctx, values, []
      else
        fn.call ctx, [], values

      # Notifies watchers unless it is known the value has not
      # changed.
      unless changed is false
        watcher.values[namespace] = ctx.value
        if namespace is 'common'
          collection.touch watcher.consumers
        else
          collection.touch (namespace.substr 1)

  processOne = (event, item) ->
    process event, [item]

  # Sets up the watch based on the provided criteria.
  #
  # TODO: provides a way to clean this when no longer used.
  keys = $asArray (keys ? key ? [])
  rules = $asArray (rules ? rule ? [])
  if not $_.isEmpty keys
    # Matching is done on the keys.

    throw new Error 'cannot use keys and rules' unless $_.isEmpty rules

    $_.each keys, (key) -> collection.on "key=#{key}", processOne

    # Handles existing items.
    process 'enter', collection.getRaw keys
  else if not $_.isEmpty rules
    # Matching is done the rules.

    $_.each rules, (rule) -> collection.on "rule=#{rule}", process

    # TODO: Inefficient, is there another way?
    rules = do -> # Minor optimization.
      tmp = Object.create null
      tmp[rule] = true for rule in rules
      tmp
    $_.each collection.getRaw(), (item) ->
      processOne 'enter', item if item.rule of rules
  else
    # No matching done.

    collection.on 'any', process

    # Handles existing items.
    process 'enter', collection.getRaw()

  # Returns the watcher object.
  watcher

#=====================================================================

# Creates a set of value from various items.
$set = (options) ->
  # Contrary to other helpers, the default value is the key.
  options.val ?= -> @key

  options.init = []

  watcher = $watch this, options, (entered, exited) ->
    changed = false

    for value in entered
      if @value.indexOf value is -1
        @value.push value
        changed = true

    for value in exited
      changed = true if $removeValue @value, value

    changed

  watcher.generator

#---------------------------------------------------------------------

$sum = (options) ->
  options.init ?= 0

  watcher = $watch this, options, (entered, exited) ->
    prev = @value

    @value += value for value in entered
    @value -= value for value in exited

    @value isnt prev

  watcher.generator

#---------------------------------------------------------------------

# Uses a value from another item.
#
# Important note: Behavior is not specified when binding to multiple
# items.
$val = (options) ->
  # The default value.
  def = options.default
  delete options.default

  options.init ?= def

  # Should the last value be kept instead of returning to the default
  # value when no items are available!
  keepLast = !!options.keepLast
  delete options.keepLast

  watcher = $watch this, options, (entered, exited) ->
    prev = @value

    if not $_.isEmpty entered
      @value = entered[0]
    else
      @value = def unless keepLast

    @value isnt prev

  watcher.generator

#=====================================================================

module.exports = {
  $set
  $sum
  $val
}
