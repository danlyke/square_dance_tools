#!/usr/bin/perl -w
use warnings;
use strict;
use Data::Dumper;
use JSON;
use File::Slurp;

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
     formations => [],
    };
    
    return undef unless (defined($line = <$fh>) || $line =~ /\x0c/);
    $line =~ s/^\s+//xsg;
    $line =~ s/\s+$//xsg;
    $sequence->{description} = $line;
    my @formation = ();
    
    while (defined($line = <$fh>) && $line !~ /\x0c/)
    {
        chomp $line;
        if ($line eq '' || $line =~ /^\s/xs)
        {
            print "Pushing formation $line\n";
            push @formation, $line;
        }
        else
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
                push @{ $sequence->{formations} }, [ @formation ]; 
               @formation = ();
            }
        }
    }
    $sequence->{resolve} = pop @{ $sequence->{moves} };
    return $sequence;
}

sub parse_sd_file
{
    my ($filename) = @_;
    open my $fh, '<', $filename
        || die "Unable to open $filename for reading";
    my @sequences;
    
    while (my $sequence = get_next_sequence($fh))
    {
        push @sequences, $sequence;
    }

    close $fh;
    return @sequences;
}

sub write_sequences_to_sd
{
    my ($intermediate_file, @sequences) = @_;

    my $sdcmd = './sdtty';
    open my $ofh, '|-', "$sdcmd -sequence '$intermediate_file' -keep_all_pictures -no_graphics -no_color"
        || die "unable to open for writing\n";
#    print $ofh "0\n";
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



sub write_js_file
{
    my ($jsonfile, @sequences) = @_;
    open my $ofh, '>', $jsonfile
        || die "Unable to open $jsonfile for writing";
    print $ofh "sequences = ".to_json(\@sequences, { pretty => 1 }  ).";\n";
    print $ofh <<'EOF';
for (counter = 0; counter < sequences.length; counter++)
{
    console.log(sequences[counter].description);
}
EOF
    close $ofh;
}


sub write_html_file
{
    my ($htmlfile, @sequences) = @_;
    open my $ofh, '>', $htmlfile
        || die "Unbale to open $htmlfile for writing\n";
    
    print $ofh <<'EOF';
<!DOCTYPE html>
<html><head><title>Main Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<style type="text/css">
.currentCall {
background-color: red;
};
</style>
<link href="/favicon.ico" rel="icon" type="image/ico">
<link href="/favicon.ico" rel="shortcut icon">
</head>
<body>
<div style="
    height: 40px; 
    position: fixed; 
    bottom:0%;
    width:100%; 
    border: 1px red;
    opacity: 1;
">
<a href="#" onClick="goToNextCall()">Next Call</a>
<a href="#" onClick="goToPreviousCall()">Prev Call</a> <span id="sequence_title"></span>
</div>
<div id="search" style="
    visibility: hidden;
    height: 33%;
    position: fixed; 
    top:0%;
    width:33%; 
    right:0;
    border: 1px red;
    opacity: 1;
"><a href="#" onClick="displayFormations();">Formations</a><br/>
Search stuff goes here


</div>
<div id="formations" style="
    height: 33%;
    position: fixed; 
    top:0%;
    width:33%; 
    right:0;
    border: 1px red;
    opacity: 1;
">
<a href="#" onClick="displaySearch()">Search</a><br/>
<pre id="formation_view">
 4B>   3G<   3B>   2G<

 4G>   1B<   1G>   2B<
</pre></div>
<div style="
    height: 66%;
    position: fixed; 
    top:33%;
    width:33%; 
    right:0;
    border: 1px red;
    opacity: 1;
    overflow: scroll;
"><ul id="call_list">
</ul>
</div>
<div style="
overflow:scroll;
position: fixed;
top: 0;
left: 0;
width: 66%;
bottom: 40px;
">
<ul id="sequence">
</ul>
</div>
EOF

    print $ofh <<'EOF';
<script type="text/javascript">
EOF
    print $ofh "sequences = ".to_json(\@sequences, { pretty => 1 }  ).";\n";
    print $ofh <<'EOF';
</script>
EOF
    print $ofh <<'EOF';
<script type="text/javascript">//<![CDATA[
EOF

    print $ofh read_file('callcoordination.js');

    print $ofh <<'EOF';

//]]>
</script>

EOF
    close $ofh;
}

sub change_extension
{
    my ($filename, $extension) = @_;
    my $newfile = $filename;
    $newfile =~ s/\.\w{3,4}$//;
    $newfile .= ".$extension";
    return $newfile;
}


for my $filename (@ARGV)
{
    my @sequences = parse_sd_file($filename);
    
    print Dumper(\@sequences);

    my $tempfile = 'test.txt';
    unlink $tempfile;
    write_sequences_to_sd($tempfile, @sequences);
    my $htmlfile = change_extension($filename, 'html');
    my $jsfile = change_extension($filename, 'js');
    my @newsequences = parse_sd_file($tempfile);
    write_html_file("/var/www/squaredancehelper/$htmlfile", @newsequences);
    write_js_file("/var/www/squaredancehelper/$jsfile", @newsequences);
}
