assert = require "assert"
path   = require "path"

describe "config.json", ->

  config =
    try
      require path.resolve 'config.json'
    catch err
      err

  it 'should be valid json', ->

    assert.ok !(config instanceof Error)

  it 'should have property "interval"', ->

    assert.equal typeof config['interval'], 'number'

  it 'should have property "slack"', ->

    assert.equal typeof config['slack'], 'object'

  it 'should have feeds', ->

    assert.ok config['feeds'] instanceof Array
