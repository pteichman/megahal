#!/usr/bin/perl -w
#
# Megahal IRC bot.
# By Joey Hess <joey@kitenet.net> GPL 1998
#
# This needs the debian patched version of megahal, with #quiet command
# and prompt to stderr output. It also needs Hal.pm and the Net::IRC module.
#
# Version: 1.2

# Local configuration.
my $server=shift || 'irc.debian.org';
# Multiple channels may be separated by ':' characters.
my $channel=shift || "#megahal";
my $nick=shift || "megahal";
my $ircname=shift || "Megahal";
my $port=shift || 6667;
my $howvocal=shift || 10; # percentage of the time it talks publically
my $save_interval=shift || 60 * 10; # how often to save megahal's brain

my @ignore=('dpkg','apt','||');	# other bots and idiots to ignore
my $verbose=1;

#

use strict;
use Net::IRC;
use Hal;

# Catch ctrl-c properly and stop megahal.
$SIG{TERM}=sub {
	Hal::quit();
	exit;
};
$SIG{INT}=$SIG{TERM};

# Set everything up.
push @ignore,$nick;

my $last_save=time();

my $greet=Hal::start();

my $irc=Net::IRC->new;
my $conn=$irc->newconn(
	Nick => $nick,
	Server => $server,
	Port => $port,
	Ircname => $ircname,
);
$conn->add_handler('376', \&on_connect); # 376 = end of MOTD: we're connected.
$conn->add_handler('msg', \&on_msg);
$conn->add_handler('public', \&on_public);
$conn->add_handler('kick', \&on_kick);

$irc->start;

# What to do when the bot successfully connects.
sub on_connect {
	my $self=shift;
	my $chan;
	
	foreach my $chan (split(/:/, $channel)) {
		print "Joining $chan..\n" if $verbose;
		$self->join($chan);
	
		# Say hi (or something vaguely along those lines).
		print "<$nick> $greet\n";
		$self->privmsg($chan,$greet);
	}
	
}

# Listen to dialog on the channel and send it to megahal for processing.
sub on_public {
	my $self=shift;
	my $event=shift;
	
	my $from=$event->nick;
	my $chan=$event->to;
	
	return if grep {$from eq $_} @ignore;
	
	$_=join("\n",$event->args)."\n";
	s/[\x00-\x1f]//g; # no bold crap.
	
	return if /^\!.*/; # other bot talk (ie, eggdrop).
	
	print "<$from> $_\n" if $verbose;
	if (/^$nick[:,;](.*)/i) {
		if ($1) {
			my $ret="$from: ".Hal::talk($1."\n");
			# Respond in kind. Sometimes privatly, sometimes
			# publically. Making it always respond publically
			# is bad if you want to use the channel it's on
			# for anything else, people tend to abuse the bot.
			if (rand() * 100 <= $howvocal) {
				print "<$nick> $ret";
				$self->privmsg($chan,$ret);
			}
			else {
				print "($nick) $ret";
				$self->privmsg($from,$ret);
			}
		}
	}
	else {
		# Let's try to strip out nicks and other garbage.
		s/^.*?[:,;]//;
		# Send it quietly - no reply is generated, to save CPU.
		Hal::tell($_) if $_;
	}

	CheckSave();
}


# Listen to private messages, send to megahal for processing, and respond
# privatly.
sub on_msg {
	my $self=shift;
	my $event=shift;
	
	my $from=$event->nick;
	
	return if grep {$from eq $_} @ignore;
	
	$_=join("\n",$event->args)."\n";
	s/[\x00-\x1f]*//g; # no bold crap.
	
	print "($from) $_\n";
	my $ret=Hal::talk($_);
	print "($nick) $ret";
	$self->privmsg($from,$ret);

	CheckSave();
}

# Check to see if it's been long enough since the last save for us to save
# megahal's brain again.
sub CheckSave {
	if ($last_save + $save_interval < time()) {
		$last_save=time();
		Hal::save();		
	}
}

# Auto-join on kick
sub on_kick {
	my $self=shift;
	my $event=shift;
	my $from=$event->nick;
	my @stuff=$event->args;
	my $chan=$stuff[0];
	my $reason=$stuff[1];

	$self->join($chan);
	my $ret="$from: ".Hal::talk($reason."\n");
	$self->privmsg($chan, $ret);
}

# All this and I still doen't understand IRC. Scaaaarey! -- Joey
