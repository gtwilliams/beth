#!/usr/bin/perl
# Copyright (c) 2019 Garry T. Williams.  All rights reserved.

foreach my $f (@ARGV) {
    open my $fh, '<', $f or die "can't open $f: $!\n";
    my @hdrs;
    my $n = <$fh>;
    unless ($n =~ /\A\d+\n\z/) {
        chomp $n;
        warn "first line unexpected value: $n\n";
    }

    while (<$fh>) {
        last if $_ eq "\n";
        chomp;
        push @hdrs, $_
    }

    # Find Content-Type header for boundary.
    my $b;
    for (@hdrs) {
        if (/\AContent-Type:/i) {
            if (/boundary="([^"]+)"/) {
                $b = $1;
                last;
            }
        }
    }

    my (@parts, $footer);
    if ($b) {
        my $part;
        while (<$fh>) {
            if (/$b/) {
                if ($part) {
                    push @parts, $part;
                }

                $part = $_;
                next;
            }

            # Consume leading blank lines befor first boundary.
            unless ($part) {
                next if /\A\n\z/;
            }

            $part .= $_;
        }


        if ($part =~ /<\?xml version=/) {
            $part =~ s/\A--$b--\n//;
            $footer = $part;
            $parts[-1] =~ s/\A--$b\n/--$b--\n/;
        }
    }

    else {
        my $part;
        while (<$fh>) {
            if ($footer) {
                $footer .= $_;
                next;
            }

            if (/\A<\?xml version=/) {
                $footer .= $_;
                next;
            }

            else {
                $part .= $_;
            }
        }

        push @parts, $part if $part;
    }

    for (@hdrs) {
        print "$_\n";
    }

    print "\n";

    print $_ for @parts;

    # Extract the sender mail address
    #if ($footer =~ m{sender</key>\s+<string>([^<]+)<}) {
    #   print "sender: $1\n";
    #}
}

# vim: sw=4 sts=4 ts=8 et

__END__

