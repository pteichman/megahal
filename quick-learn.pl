#!/usr/bin/perl

use warnings;
use strict;
use Megahal;

Megahal::megahal_initialize();

while (<STDIN>) {
	Megahal::megahal_learn_no_reply($_, 1);
}

Megahal::megahal_cleanup();
