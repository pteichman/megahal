#!/usr/bin/python

# MegaHAL quick learning script.
# By Laurent Fousse <laurent@komite.net> GPL 2003
#
# Usage: quick-learn < text-file
# reads text-file linewise and feeds it to megahal


import mh_python
import sys

mh_python.initbrain()

while 1:
	ligne = sys.stdin.readline()
	if not ligne: break
	mh_python.learn(ligne)

mh_python.cleanup()
