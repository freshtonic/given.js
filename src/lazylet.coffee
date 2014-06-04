
# Function.prototype.bind is absent in PhantomJS. Implement it ourselves.
bind = (fn, self) ->
  -> fn.apply self, arguments

asFn = (valueOrFn) ->
  if typeof valueOrFn is 'function'
    valueOrFn
  else
    -> valueOrFn

getter = (obj, name, fn) ->
  Object.defineProperty obj, name,
    get: fn
    configurable: true
    enumerable: true

LazyLet =
  Env: ->
    env   = {}
    funs  = {}
    memos = {}

    resetEnv = ->
      funs = {}
      memos = {}
      for name in Object.keys(env) when name isnt 'Let'
        delete env[name]

    memoize = (name, fn) ->
      ->
        memo = memos[name]
        if memo?
          memo
        else
          memos[name] = fn()

    isStackOverflowError = (err) ->
      message = (if typeof err is 'string' then err else err?.message) or ''
      message.match /\bstack|recursion\b/

    trapStackOverflow = (name, fn) ->
      ->
        try
          fn()
        catch err
          if isStackOverflowError err
            throw "recursive definition of variable '#{name}' detected"
          else
            throw err

    # Redefine an existing variable.
    # This specifically supports the case where a variable is defined in terms
    # of its existing value (avoiding stack overflow). This is achieved by
    # running the most recent definition for computing the variable in a new
    # environment that prototypically inherits the old one.
    redefine = (name, fn) ->
      newEnv       = Object.create env
      oldFn        = funs[name]
      getter newEnv, name, bind(oldFn, env)
      newFn        = bind fn, newEnv
      getter env, name, newFn
      newFn

    defineOneVariable = (name, valueOrFn) ->
      throw 'cannot redefine Let' if name is 'Let'

      memos = {}

      fn = asFn valueOrFn

      if funs[name]?
        fn = redefine name, fn
      else
        getter env, name, memoize(name, trapStackOverflow(name, bind(fn, env)))

      funs[name] = fn

    defineInBulk = (object) ->
      for name, thing of object
        defineOneVariable name, thing

    # The arguments to this function are (name, thing) or (object).
    # The second form is for defining variables in bulk.
    Let = ->
      args = [].slice.apply arguments
      if typeof args[0] is 'object'
        defineInBulk args[0]
      else
        [name, thing] = args
        defineOneVariable name, thing

    Object.defineProperty env, 'Let',
      writable: false
      configurable: false
      value: Let

    Object.defineProperties Let,
      clear:
        writable: false
        configurable: false
        value: resetEnv

    env

if (typeof module isnt 'undefined') and module.exports?
  module.exports = LazyLet
else
  @LazyLet = LazyLet
