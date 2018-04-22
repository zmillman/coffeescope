"use strict"
{nodes} = require "coffeescript"

ScopeLinter = require "../../src/ScopeLinter"


describe "ScopeLinter/unused", ->
    it "matches trivial cases", ->
        ScopeLinter.default().lint(nodes(
            """
            foo = "bar"
            {bar} = "bar"
            """
        ), {
            unused_variables: true
        }).should.have.length(2)

        ScopeLinter.default().lint(nodes(
            """
            (foo) ->
                undefined

            ({foo}) ->
                undefined

            ({foo} = {foo: bar}) ->
                undefined
            """
        ), {
            unused_arguments: true
        }).should.have.length(3)


    it "matches classes", ->
        ScopeLinter.default().lint(nodes(
            """
            class Foo
            """
        ), {
            unused_classes: true
        }).should.have.length(1)

        ScopeLinter.default().lint(nodes(
            """
            class Foo

            class Bar extends Foo
            """
        ), {
            unused_classes: true
        }).should.have.length(1)


    it "supports classes as properties", ->
        ScopeLinter.default().lint(nodes(
            """
            PROP = "Bar"
            obj = {}

            class obj.Foo
            class obj[PROP]
            """
        ), {
            unused_classes: true,
            unused_variables: true
        }).should.have.length(0)


    it "ignores assigned classes", ->
        ScopeLinter.default().lint(nodes(
            """
            Bar = class Foo

            Bar
            """
        ), {
            unused_classes: true
        }).should.have.length(0)

        ScopeLinter.default().lint(nodes(
            """
            class Foo

            Baz = class Bar extends Foo

            Baz
            """
        ), {
            unused_classes: true
        }).should.have.length(0)


    it "matches recursive assignments", ->
        ScopeLinter.default().lint(nodes(
            """
            intervalId = setInterval ->
              clearInterval intervalId
            , 50
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "doesn't match named classes that are part of an assignment", ->
        ScopeLinter.default().lint(nodes(
            """
            Bar = class Foo
            Bar
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches for loops", ->
        ScopeLinter.default().lint(nodes(
            """
            for i in [1,2,3,4]
                undefined

            for i, index in [1,2,3,4]
                undefined

            for i in [0..4]
                undefined

            for i of {foo: "bar"}
                undefined

            for i, index of {foo: "bar"}
                undefined
            """
        ), {
            unused_variables: true
        }).should.have.length(7)


    it "issues multiple errors for the same value", ->
        ScopeLinter.default().lint(nodes(
            """
            foo = "bar"
            {foo} = "bar"
            """
        ), {
            unused_variables: true
        }).should.have.length(2)


    it "ignores object literals", ->
        ScopeLinter.default().lint(nodes(
            """
            {bar: "baz"}
            """
        ), {
            unused_arguments: true
            unused_variables: true
        }).should.have.length(0)


    it "matches indirect access", ->
        ScopeLinter.default().lint(nodes(
            """
            foo = {}
            foo[bar]
            foo.bar
            foo[0]
            foo.bar()
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "ignores builtins", ->
        ScopeLinter.default().lint(nodes(
            """
            foo = ->
                undefined
            foo()
            """
        ), {
            unused_arguments: true
            unused_variables: true
        }).should.have.length(0)


    it "ignores arguments when instructed", ->
        ScopeLinter.default().lint(nodes(
            """
            (foo) ->
                undefined
            """
        ), {
            unused_arguments: true
        }).should.have.length(1)

        ScopeLinter.default().lint(nodes(
            """
            (foo) ->
                undefined
            """
        ), {
            unused_arguments: false
        }).should.have.length(0)


    it "supports special symbol names", ->
        ScopeLinter.default().lint(nodes(
            """
            constructor = 123
            """
        ), {
            unused_variables: true
        }).should.have.length(1)


    it "matches destructured defaults", ->
        ScopeLinter.default().lint(nodes(
            """
            defaultVal = 0
            { property = defaultVal } = {}
            property
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches nested destructured expressions", ->
        ScopeLinter.default().lint(nodes(
            """
            { property: nested: val } = { property: nested: 1 }
            val
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches do statements", ->
        ScopeLinter.default().lint(nodes(
            """
            for v, k in {foo: "bar"}
                do (v, k) ->
                    console.log(v, k)
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches ranges", ->
        ScopeLinter.default().lint(nodes(
            """
            MAX_LENGTH = 3
            str = 'foobar'
            console.log str[...MAX_LENGTH]
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches explicit do statements", ->
        ScopeLinter.default().lint(nodes(
            """
            afn = (fn) -> fn()

            do afn ->
              null
            """
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches composed string field objects", ->
        ScopeLinter.default().lint(nodes(
            '''
            field = 'howdy'
            obj =
              "#{field}": 1
            obj
            '''
        ), {
            unused_variables: true
        }).should.have.length(0)


    it "matches this assignments", ->
        ScopeLinter.default().lint(nodes(
            """
            normalize = (node) -> 'foo'

            class Poll extends Driver

              constructor: ->
                super arguments...
                @deferrals = {}

              defer: (node) ->
                @deferrals[normalize(node)] = _.now()
                return
            """
        ), {
            unused_variables: true
        }).should.have.length(0)

     it "handles imports", ->
         ScopeLinter.default().lint(nodes(
             """
             import _ from 'underscore'
             """
         ), {
             unused_variables: true
         }).should.have.length(1)

         ScopeLinter.default().lint(nodes(
             """
             import * as underscore from 'underscore'
             """
         ), {
             unused_variables: true
         }).should.have.length(1)

         ScopeLinter.default().lint(nodes(
             """
             import { now } from 'underscore'
             """
         ), {
             unused_variables: true
         }).should.have.length(1)

         ScopeLinter.default().lint(nodes(
             """
             import { now as currentTimestamp } from 'underscore'
             """
         ), {
             unused_variables: true
         }).should.have.length(1)

         ScopeLinter.default().lint(nodes(
             """
             import { first, last } from 'underscore'
             """
         ), {
             unused_variables: true
         }).should.have.length(2)

         ScopeLinter.default().lint(nodes(
             """
             import utilityBelt, { each } from 'underscore'
             """
         ), {
             unused_variables: true
         }).should.have.length(2)

    it "handles export of a default global", ->
        ScopeLinter.default().lint(nodes(
            """
            export default Math
            """
        ), {
            unused_variables: true
        }).should.have.length(0)

    it "handles export of a function", ->
        ScopeLinter.default().lint(nodes(
            """
            square = (x) -> x * x
            export { square }
            """
        ), {
            unused_variables: true
        }).should.have.length(0)

    it "handles export of an inline function", ->
        ScopeLinter.default().lint(nodes(
            """
            export square = (x) -> x * x
            """
        ), {
            unused_variables: true
        }).should.have.length(0)

    it "handles export of an inline class", ->
        ScopeLinter.default().lint(nodes(
            """
            export class Mathematics
              least: (x, y) -> if x < y then x else y
            """
        ), {
            unused_classes: true
        }).should.have.length(0)

    it "handles export splat from an import", ->
        ScopeLinter.default().lint(nodes(
            """
            export * from 'underscore'
            """
        ), {
            unused_variables: true
        }).should.have.length(0)

    it "handles export from a destructured import", ->
        ScopeLinter.default().lint(nodes(
            """
            export { max, min } from 'underscore'
            """
        ), {
            unused_variables: true
        }).should.have.length(0)

    it "handles export of a default class and an aliased function", ->
        ScopeLinter.default().lint(nodes(
            """
            class Mathematics
              least: (x, y) -> if x < y then x else y
            square = (x) -> x * x
            export { Mathematics as default, square as squareAlias }
            """
        ), {
            unused_variables: true
            unused_classes: true
        }).should.have.length(0)

    it "allows exceptions when instructed", ->
        ScopeLinter.default().lint(nodes(
            """
            _foo = "bar"
            class _UnusedKlass
              method: (_arg) ->
            """
        ), {
            unused_variables: true
            unused_arguments: true
            unused_classes: true
            unused_exceptions: ["_.+"]
        }).should.have.length(0)

        ScopeLinter.default().lint(nodes(
            """
            _foo = "bar"
            class _UnusedKlass
              method: (_arg) ->
            """
        ), {
            unused_variables: true
            unused_arguments: true
            unused_classes: true
            unused_exceptions: ["_..."]
        }).should.have.length(1) # only catches the unused class
