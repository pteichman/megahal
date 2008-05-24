#!/usr/bin/perl -w
#
# Communicate 2-way with a megahal process. This is a mess because
# I have to handle all the IO myself using a select loop.
#
# Joey Hess <joey@kitenet.net> GPL 1998

package Hal;
use strict;
use IPC::Open2;
use Fcntl;
use IO::Select;

my $rselect=IO::Select->new();
my $wselect=IO::Select->new();

# Start megahal running and return his first line of output.
sub start {
	my $progname=shift || "megahal-personal";
	
	my $pid=open2(\*READ, \*WRITE, $progname, 
		"--no-prompt", "--no-wrap", "--no-banner");
	_nonblock(\*READ);
	_nonblock(\*WRITE);
	$rselect->add(\*READ);
	$wselect->add(\*WRITE);
	# Now read the first line he outputs which we will return.
	return Hal::read();
}

# Pass a line of input to hal, returns everything he says until he expects
# input from you again. If the input is trusted, you must pass 1 as the
# second parameter. Otherwise, #-commands are ignored.
sub talk { 
	my $line=shift;
	my $trusted=shift;
	
	$line=~s/^\s*//;
	$line=~tr/ 	/ /s;
	
	return if (!$trusted && $line=~m/^\s*#/);
	
	$wselect->can_write();
	# TODO: partial write detection &etc.
	syswrite(WRITE,"$line\n\n",length($line)+3) || print "$!\n";
	
	return Hal::read();
}

# Read any pending output. There _must_ be some, or it'll block.
sub read {
	my $done=0;
	my $ret='';
	until ($done) {
		$rselect->can_read();
		if (sysread(READ,$_,1024)) {
			$done=1 if (/\n/);
			$ret.=$_;
		}
	}
	return $ret;
}

# Pass a line of input to hal, in quiet mode. He listens, but does not reply.
# See above for trusted input docs.
sub tell {
	my $line=shift;
	my $trusted=shift;

	$line=~s/^\s*//;
	$line=~tr/ 	/ /s;

	return if (!$trusted && $line=~m/^\s*#/);
	
	$wselect->can_write();
	# TODO: partial write detection &etc.
	syswrite(WRITE,"#quiet\n\n$line\n\n#quiet\n\n",length($line)+20) || print "$!\n";
}

# Exit cleanly.
sub quit {
	$wselect->can_write();
	syswrite(WRITE,"#quit\n\n",8);
}

# Save brain.
sub save {
	$wselect->can_write();
	syswrite(WRITE,"#quiet\n\n#save\n\n#quiet\n\n");
}

# Set a socket into nonblocking mode.
sub _nonblock {
	my $socket=shift;
	my $flags= fcntl($socket, F_GETFL, 0) 
		or die "Can't get flags for socket: $!\n";
	fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
		or die "Can't make socket nonblocking: $!\n";
}

1
