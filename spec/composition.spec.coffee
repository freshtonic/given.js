
xdescribe 'composition', ->

  compose = (fn1, fn2) -> -> fn1 fn2.apply null, arguments

  composeAll = (fns) ->
    fns.reverse().slice(1).reduce (fn, fnNext) ->
      compose fn, fnNext
    , fns[0]

  sequence = (f1, f2) -> -> f2 f1

  sequenceAll = (fns) ->
    fns.slice(1).reduce (fn, fnNext) ->
      sequence fn, fnNext
    , fns[0]


  it 'should work for one function', ->
    f = -> 1
    c = composeAll [f]
    expect(c()).toBe 1

  it 'should work for two functions', ->
    f1 = (a) -> a * 2
    f2 = (a) -> a + 1
    c = composeAll [f1, f2]
    expect(c(1)).toBe 3

  it 'the order matters', ->
    f1 = (a) -> a.concat 'f1'
    f2 = (a) -> a.concat 'f2'
    f3 = (a) -> a.concat 'f3'
    c = composeAll [f1, f2, f3]
    expect(c([])).toEqual ['f1', 'f2', 'f3']

  iit 'works for functions that take functions as arguments', ->

    result = []
    f1 = (fn) -> result.push fn()
    f2 = (fn) -> result.push fn()
    f3 = (fn) -> result.push 'f3'

    c = sequenceAll [f1, f2, f3]
    c()
    expect(result).toEqual ['f3']


