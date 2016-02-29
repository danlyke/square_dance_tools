#!/usr/bin/perl -w
use warnings;
use strict;
use Data::Dumper;
use JSON;
use File::Slurp;
use Expect;

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

    do
    {
        return undef unless (defined($line = <$fh>) || $line =~ /\x0c/);
        $line =~ s/^\s+//xsg;
        $line =~ s/\s+$//xsg;
        if ($line ne '')
        {
            $line =~ s/\s+/\ /xsg;
            $sequence->{description} .= " $line";
        }
    }
    while ($line ne '');
    
    my @formation = ();

    while (defined($line = <$fh>) && $line !~ /\x0c/)
    {
        chomp $line;
        if ($line eq '')
        {
        }
        elsif ($line =~ /^\s+/xs)
        {
            $line =~ s/^ //g;
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
                elsif ($line =~ s/^From\s+squared\s+set\s*$//xsi)
                {
                    $sequence->{opening} = 'just as they are';
                }
                elsif ($line =~ s/^(heads|sides)\s+//xsi)
                {
                    $sequence->{opening} = "$1 start";
                }
            }
            my $move = $line;
            
            if ($line ne '')
            {
                my $move = $line;
                while (defined($line = <$fh>) && $line !~ /\x0c/
                       && $line !~ /^\s+Warning\:.*/
                       && $line =~ /^\s+(\S.*)$/)
                {
                    $move .= " $1";
                }
                push @{ $sequence->{moves} }, $move;
                push @{ $sequence->{formations} }, [ @formation ]; 
                @formation = ();
                last if (!defined($line) || $line =~ /\x0c/);
            }
        }
        last if !defined($line);
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
    
    while (!eof($fh) && (my $sequence = get_next_sequence($fh)))
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
    my $exp = Expect->spawn($sdcmd,
                            '-sequence',
                            $intermediate_file,
                            '-keep_all_pictures',
                            '-no_graphics',
                            '-no_color')
        || die "unable to open for writing\n";

    my $timeout = 15;
    my $sequences = \@sequences;
    my $moves = [];
    my $comments = [];

    while (@$sequences)
    {
        $exp->expect
            ($timeout,
             [ 'Enter the level: ' =>
               sub
               {
                   my ($exp, $sequences) = @_;
                   print "Sending: "."$sequences->[0]->{level}\n";
                   $exp->send("$sequences->[0]->{level}\n");
               }, $sequences
             ],
             [ 'Enter startup command> ' =>
               sub
               {
                   my ($exp, $sequences, $movesref) = @_;
                   print "Startup with $movesref\n";
                   push @$movesref, ( 'toggle concept levels', @{$sequences->[0]->{moves}} );
                   print "Sending: "."$sequences->[0]->{opening}\n";
                   $exp->send("$sequences->[0]->{opening}\n");
               }, $sequences, $moves
             ],
             [ '\-\-\> ' =>
               sub
               {
                   my ($exp, $sequences, $movesref, $commentsref) = @_;
                   if (@$sequences) {
                       if (@$movesref) {
                           my $move = shift @$movesref;
                       
                           if ($move =~ s/\s*\{\s*(.*?)\s*\}\s*//) {
                               print "Sending: ". "insert a comment\n" ;
                               $exp->send( "insert a comment\n" );
                               push @$commentsref, $1;
                               unshift @$movesref, $move;
#                           } elsif ($move =~ s/^(.*?)\,\s+//) {
#                               print "Sending: "."$1\n";
#                               $exp->send("$1\n");
#                               unshift @$movesref, $move;
                           } else {
                               print "Sending: "."$move\n";
                               $exp->send("$move\n");
                           }
                       } else {
                           push @$commentsref, $sequences->[0]->{description};
                           print "Pushing description to ".Dumper($commentsref);
                           print "Sending: ". "write this sequence\n" ;
                           $exp->send( "write this sequence\n" );
                           shift @$sequences;
                       }
                   } else {
                       print "Sending: "."exit\n";
                       $exp->send("exit\n");
                       $exp->soft_close();
                   }
               
               }, $sequences, $moves, $comments
             ],
             [ 'Enter comment: ' =>
               sub
               {
                   my ($exp, $commentsref) = @_;
                   print "Comments ref is ".Dumper($commentsref);
                   my $comment = '';
                   if (@$commentsref) {
                       $comment = shift(@$commentsref);
                   }
                   print "Sending: "."$comment\n";
                   $exp->send("$comment\n");
               }, $comments
             ],
             [ 'Do you want to write it anyway\? ',
               sub
               {
                   my ($exp) = @_;
                   $exp->send("y");
               }
             ],
            );
    }
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

    my $control_height = '80px';
    print $ofh <<'EOF';
<!DOCTYPE html>
<html><head><title>Main Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" >
<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;">

<style type="text/css">
.currentSequence {
background-color: red;
}
.currentCall {
background-color: red;
}
</style>
<link href="/favicon.ico" rel="icon" type="image/ico">
<link href="/favicon.ico" rel="shortcut icon">
</head>
<body>
<div style="
top: 90%;
left: 0px;
width: 66%;
    height: $control_height; 
    position: fixed; 
    width:100%; 
    border: 1px red;
    opacity: 1;
    font-size: 200%;
">
<div style="float:left;">
<img id="nextCallButton" src="DownArrow.png" />
<img id="previousCallButton" src="UpArrow.png" />
</div>
<span id="sequence_title"></span>
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
    font-size: 180%;
    text-align: center;
">
<a href="#" onClick="displaySearch()">Search</a><br/>
<pre id="formation_view">
 4B>   3G<   3B>   2G<

 4G>   1B<   1G>   2B<
</pre></div>
<div style="
    position: fixed; 
    top:33%;
    width:33%; 
    height: 56%;
    right:0;
    border: 1px red;
    opacity: 1;
    font-size: 150%;
    overflow: scroll;
    overflow-y: scroll;
"><ul id="call_list"></ul>
</div>

<div style="
overflow:scroll;
position: fixed;
top: $control_height;
left: 0;
width: 66%;
overflow: scroll;
font-size: 300%;
height: 90%;
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
    print Dumper(@sequences);
    
    if (1)
    {
        my $tempfile = 'test.txt';
        unlink $tempfile;
        write_sequences_to_sd($tempfile, @sequences);
        my $htmlfile = change_extension($filename, 'html');
        my $jsfile = change_extension($filename, 'js');
        my @newsequences = parse_sd_file($tempfile);
#        print Dumper(\@newsequences);

        write_html_file("/var/www/squaredancehelper/$htmlfile", @newsequences);
        write_js_file("/var/www/squaredancehelper/$jsfile", @newsequences);
    }
}
