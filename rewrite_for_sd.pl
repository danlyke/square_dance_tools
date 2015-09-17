#!/usr/bin/perl -w
use warnings;
use strict;
use Data::Dumper;

my @months = qw/
Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
               /;

my @dows = qw/ Sun Mon Tue Wed Thu Fri Sat /;

sub get_next_sequence
{
    my ($fh) = @_;
    my $months = join('|', @months);
    my $dows = join('|', @dows);
    my %months;
    my $monthnum = 0;
    $months{$_} = ++$monthnum for @months;
    
    my $line;

    my $headregex = "($dows)\\s+($months)\\s+(\\d+)\\s+(\\d+\\:\\d+\\:\\d+)\\s+(\\d+)";
    while (defined($line = <$fh>) && $line !~ /\x0c/
          && $line !~ /$headregex/)
    {
        print "$line didn't match dows\n";
    }

    return unless $line =~ /$headregex/;
    print "($1 && $2 && $3 && $4 && $5)\n";
        
    my $sequence =
    {
     date => sprintf('%4.4d-%2.2d-%2.2d %s', $5, $months{$2}, $3, $4),
     moves => [],
    };
    
    return undef unless (defined($line = <$fh>) && $line !~ /\x0c/);
    $line =~ s/^\s+//xsg;
    $line =~ s/\s+$//xsg;
    $sequence->{description} = $line;
    
    while (defined($line = <$fh>) && $line !~ /\x0c/)
    {
        unless ($line =~ /^\s/xs)
        {
            unless (defined($sequence->{opening}))
            {
                if ($line =~ s/^(heads|sides\s+1p2p)\s*$//xs)
                {
                    $sequence->{opening} = $1;
                }
                elsif ($line =~ s/^(heads|sides)\s+//xs)
                {
                    $sequence->{opening} = "$1 start";
                }
            }
            if ($line ne '')
            {
                push @{ $sequence->{moves} }, $line;
            }
        }
    }
}

for my $filename (@ARGV)
{
    open my $fh, '<', $filename
        || die "Unable to open $filename for reading";

    my @sequences;
    
    while (my $sequence = get_next_sequence($fh))
    {
        push @sequences, $sequence;
    }

    close $fh;

    print Dumper(\@sequences);
}
