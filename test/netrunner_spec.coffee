chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'hubot-netrunner', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/netrunner')(@robot)

  describe 'quotes', ->
    it 'registers a respond listener for "netrunner {query}"', ->
      expect(@robot.respond).to.have.been.calledWith /netrunner (.*)\b/i

  describe 'images', ->
    it 'registers a respond listener for "nrdb {type} {query}"', ->
      expect(@robot.respond).to.have.been.calledWith /nrdb (.*)\b/i
