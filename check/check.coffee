
Given = require(process.cwd() +  '/build/given')
JSC   = require(process.cwd() + '/vendor/jscheck').JSC
_     = require(process.cwd() + '/vendor/underscore')

JSC.reps 10

failed = false

JSC.on_report (str) ->
  console.warn str
  if failed
    process.exit 1

JSC.on_result (result) ->
  if not result.ok
    console.error 'FAILED'
    failed = true

# Helper function to sample a random element from an array.
sample = (things) ->
  things[parseInt Math.random() * things.length]

randomKey = (declarationCount) ->
  "key_#{parseInt Math.random() * declarationCount}"

# Finds keys that are safe for reuse - i.e. keys where reuse will not cause
# a recursive definition of a value.  The algorithm finds all keys that do not
# produce a reachability cycle to *toKey*.  The exception to the rule is that
# keys are allowed allowed to refer to their own previous definitions.
keysSafeForReuse = (toKey, declarations) ->
  keys = _.uniq declarations.map (decl) -> decl[0]
  _.filter keys, (key) ->
    not reaches(declarations, toKey, key)

reaches = (declarations, toKey, key) ->


# A JSC specifier for generating Given environment of definitions and
# redefinitions.  Some definitions will have no dependencies, some will
# have multiple dependencies, some will be redefinitions and some will not.
declarations = ({maxDefinitions}) ->

  _maxDefinitions = maxDefinitions()

  generate = ->

    declarations = []

    nextKeyName = ->
      "key_#{declarations.length}"

    for n in [0..._maxDefinitions]

      if declarations.length is 0
        declarations.push [ nextKeyName(), [ JSC.integer(100)() ] ]
      else
        shouldRedefine  = Math.random() < 0.5
        key = if shouldRedefine
          randomKey declarations.length
        else
          nextKeyName()

        valueCount = parseInt 1 + Math.random() * 10
        definition = for n in [0...valueCount]
          shouldReuse     = Math.random() < 0.5
          if shouldReuse
            randomKey declarations.length
          else
            JSC.integer(123)()

        declarations.push [key, definition]

    declarations

  generate

makeDefinitionFunction = (decl) ->
  ->
    total = 0
    for expression in decl[1]
      if typeof expression is 'string'
        total += this[expression]
      else
        total += expression
    total

buildGivenEnvironment = (declarations) ->
  obj = {}
  given = Given obj
  for decl in declarations
    given decl[0], makeDefinitionFunction decl
  obj

checkCanEvaluate = (obj) ->
  try
    for key in Object.keys obj
      obj[key]
    true
  catch err
    console.error err
    false

JSC.test(

  "Definitions are always memoized"

  (verdict, declarations) ->
    verdict checkCanEvaluate buildGivenEnvironment declarations

  [
    declarations maxDefinitions: JSC.integer(100)
  ]
)

# circular definitions fail with correct exception
# forward declarations always work
# illegal env access is always detected



