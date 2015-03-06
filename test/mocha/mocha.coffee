chai = require 'chai'
expect = chai.expect

describe.only "Simple mocha test", ->
  it "should add two numbers", ->
  	expect(2+2).is.equal 4
