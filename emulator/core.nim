# APHELION EMULATOR 1.0
# BY TECHNICHRON

import std/strutils, std/sequtils

# ----------------------------------- setup ---------------------------------- #

var Memory: array[65536, uint8]

var programCounter:uint16 = 0

var RegisterA: uint8    # general
var RegisterB: uint8    # general
var RegisterC: uint8    # general
var RegisterD: uint8    # general
var RegisterE: uint8    # general
var RegisterL: uint8    # general / low index register
var RegisterH: uint8    # general / high index register
var RegisterF: uint8    # flags: 000, carry, borrow, equal, less, zero

