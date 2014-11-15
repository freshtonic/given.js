
# Function.prototype.bind is absent in PhantomJS.
bind = (fn, self) -> -> fn.apply self, arguments

defineGetter = (obj, name, fn) ->
  Object.defineProperty obj, name,
    get: fn
    configurable: true
    enumerable: true

Given = (self) ->
  privateEnv           = {}
  env                  = self or {}
  funs                 = {}
  memos                = {}
  definitionCount      = 0

  topmostVariableBeingEvaluated = undefined
  entered                       = -> topmostVariableBeingEvaluated?

  failOnReenter = (name) -> ->
    if entered()
      throw new Error "
        Illegal attempt to use the Given environment object
        in the definition of '#{topmostVariableBeingEvaluated}'; Use
        'this' within value definitions.
      "
    else
      privateEnv[name]


  # Empties the environment and associated internal bookkeeping. *env* is
  # handled specially: it may be the 'this' of the test under execution so
  # replacing with a brand new object is not an option.
  resetEnv = ->
    for own name of privateEnv when name isnt 'given'
      delete env[name]
    funs = {}
    memos = {}
    privateEnv = {}
    definitionCount = 0

  # Compute the value of the variable identified by *name*, returning a cached
  # value if it is already computed.
  memoize = (key) ->
    (fn) ->
      memo = memos[key]
      if memo?
        memo
      else
        memos[key] = fn()

  # Detect whether an error is a stack overflow. This way these errors are
  # thrown is inconsistent across JavaScript implenentations so this function
  # quite likely needs more work in order to be reliable.
  isStackOverflowError = (err) ->
    message = (if typeof err is 'string' then err else err?.message) or ''
    message.match /\bstack|recursion\b/

  # Trap stack overflow errors so that an appropriate warning message about
  # recursive variable definitions can be produced.
  trapStackOverflow = (name) -> (fn) ->
    try
      fn()
    catch err
      if isStackOverflowError err
        throw new Error "recursive definition of variable '#{name}' detected"
      else
        throw err

  # Tracks which variable is currently being evaluated. This is the name of the
  # variable which was deferenced at the top-level environment object (the one
  # passed as an argument to *Given*).  To avoid subtle bugs, the definition
  # of a variable should not use the top-most Given environment. The
  # *topmostVariableBeingEvaluated* is checked in *failOnReenter*.
  trapOuterEnvAccess = (name) -> (fn) ->
    topmostVariableBeingEvaluated = name
    try
      fn()
    finally
      topmostVariableBeingEvaluated = undefined

  # Redefine an existing variable.
  # This specifically supports the case where a variable is defined in terms
  # of its existing value (avoiding stack overflow). This is achieved by
  # running the most recent definition for computing the variable in a new
  # environment that prototypically inherits the old one.
  redefine = (name, fn) ->
    newEnv       = Object.create privateEnv
    oldFn        = funs[name]
    defineGetter newEnv, name, bind(oldFn, privateEnv)
    newFn        = define newEnv, fn, name
    defineGetter privateEnv, name, newFn
    newFn

  # The composition of a pipeline of handlers for computing the value of
  # a variable in the Given environment.  Written in a style that linearizes the
  # stages in the order they are executed.
  define = (env, definitionFn, name) ->
    definitionCount += 1
    f1 = bind definitionFn, env
    f2 = trapStackOverflow name
    f3 = trapOuterEnvAccess name
    f4 = memoize "#{name}_#{definitionCount}"
    -> f4 -> f3 -> f2 -> f1()

  isFirstDefinitionOf = (name) -> not funs[name]?

  # Defines one variable in the Given environment.
  defineOneVariable = (name, definitionFn) ->
    throw new Error 'cannot redefine given' if name is 'given'
    throw new Error "definition of \"#{name}\" is not a function" unless definitionFn instanceof Function

    # Clear all memoized values.
    memos = {}

    if isFirstDefinitionOf name
      funs[name] = define(privateEnv, definitionFn, name)
      defineGetter privateEnv, name, funs[name]
      defineGetter env, name, failOnReenter(name)
    else
      funs[name] = redefine name, definitionFn

  # Defines values in bulk.
  defineInBulk = (definitions) ->
    for own name, definition of definitions
      defineOneVariable name, definition

  # The arguments to this function are (name, thing) or (object).
  # The second form is for defining variables in bulk.
  given = ->
    args = [].slice.apply arguments
    if typeof args[0] is 'object'
      defineInBulk args[0]
    else
      [name, thing] = args
      defineOneVariable name, thing

  Object.defineProperties given,
    clear:
      writable: false
      configurable: false
      value: resetEnv
    __isGiven__:
      writable: false
      configurable: false
      value: true

  given

Given.isGiven = (obj) -> obj?.__isGiven__ or false

if (typeof module isnt 'undefined') and module.exports?
  module.exports = Given
else
  @Given = Given

