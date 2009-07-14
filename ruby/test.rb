#!/usr/bin/ruby

require 'Hal'

h = Hal.new
h.initbrain

h.learn 'this is some stuff'
h.learn 'what is this'
h.learn 'wooooo and woo'

puts h.doreply 'is'
