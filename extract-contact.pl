#!/usr/bin/perl
# Copyright (c) 2019 Garry T. Williams.  All rights reserved.

use strict;
use warnings;
use XML::Parser;

foreach my $f (@ARGV) {
    my $s;
    {
	open my $fh, '<', $f or die "can't open $f: $!\n";
	local $/;
	$s = <$fh>;
    }

    next unless $s =~ m{(<\?xml version="1.0".+</plist>)\n\z}s;

    my $plist;
    eval { $plist = XML::Parser->new(Style => 'Tree')->parse($1) };
    if ($@) {
	warn "$f: $@\n";
	next;
    }
    my $dict = $plist->[1][4];

    my $found;
    for (my $i = 0; $i < @$dict; $i++) {
	next unless $i % 4 == 3;
	if ($found) {
	    my ($name, $email);
	    if ($dict->[$i+1][2] =~ /"([^"]*)"/) {
		$name = $1;
		($email) = $dict->[$i+1][2] =~ /<([^>]+)>/;
		last unless $email;
	    }

	    elsif ($dict->[$i+1][2] =~ /([^<]+)\s+<([^>]+)>/) {
		$name = $1;
		$email = $2;
	    }

	    else {
		$name = $dict->[$i+1][2];
		($email) = $dict->[$i+1][2] =~ /<([^>]+)>/;
		last unless $email;
	    }

	    print "BEGIN:VCARD\n";
	    print "VERSION:4.0\n";
	    print "FN:$name\n";
	    print "EMAIL;TYPE=home:$email\n";
	    print "NOTE:$f\n";
	    print "END:VCARD\n";
	    last;
	}

	if ($dict->[$i] eq 'key') {
	    if ($dict->[$i+1][2] eq 'sender') {
		$found = 1;
		next;
	    }
	}
    }
}

# vim: sw=4 sts=4 ts=8 et
