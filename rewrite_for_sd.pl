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

    my $headregex = "($dows)\\s+($months)\\s+(\\d+)\\s+(\\d+\\:\\d+\\:\\d+)\\s+(\\d+)\\s+Sd[^\\s]*\\s+(.*?)(\\s|\$)";
    while (defined($line = <$fh>) && $line !~ /\x0c/
          && $line !~ /$headregex/)
    {
    }

    return unless defined($line) && $line =~ /$headregex/;
        
    my $sequence =
    {
     date => sprintf('%4.4d-%2.2d-%2.2d %s', $5, $months{$2}, $3, $4),
     level => $6,
     moves => [],
    };
    
    return undef unless (defined($line = <$fh>) || $line =~ /\x0c/);
    $line =~ s/^\s+//xsg;
    $line =~ s/\s+$//xsg;
    $sequence->{description} = $line;
    
    while (defined($line = <$fh>) && $line !~ /\x0c/)
    {
        chomp $line;
        unless ($line =~ /^\s/xs)
        {
            unless (defined($sequence->{opening}))
            {
                if ($line =~ s/^((heads|sides)\s+1p2p)\s*$//xsi)
                {
                    $sequence->{opening} = $1;
                }
                elsif ($line =~ s/^(heads|sides)\s+//xsi)
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
    $sequence->{resolve} = pop @{ $sequence->{moves} };
    return $sequence;
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

    open my $ofh, '|-', './sdtty -sequence test.txt -keep_all_pictures -no_graphics -no_color'
        || die "unable to open for writing\n";
    print $ofh "0\n";
    print $ofh "$sequences[0]->{level}\n";
    for my $sequence (@sequences)
    {
        print $ofh "$sequence->{opening}\n";

        for my $move (@{ $sequence->{moves} })
        {
            print $ofh "$move\n";
        }
        print $ofh "write this sequence\n";
        print $ofh "$sequence->{description}\n";
    }
    print $ofh "exit\n";
    close $ofh;
}
