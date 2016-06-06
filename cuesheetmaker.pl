#!/usr/bin/perl -w
use warnings;
use strict;

for my $filename (@ARGV)
{
    open my $fh, $filename
        || die "Unable to open $filename\n";

    my $basename = $filename;
    $basename =~ s/\.\w*$//;
    my $outputname = "$basename.html";
    
    open my $ofh, '>',  "/var/www/squaredancehelper/$outputname"
        || die "Unable to open $outputname for writing\n";

    print $ofh <<EOF;
<html>
<head><title>$basename</title>
<style type="text/css">
font-size: 200%;
</style>
</head>
<body>
<h1>$basename</h1>

EOF
    
    my $paragraph_open;
    
    while (my $line = <$fh>)
    {
        chomp $line;
        if ($line =~ /^(\=+)\s*(.*?)\s*\1$/)
        {
            my $level = length($1);
            my $title = $2;
            
            print $ofh "</p>\n\n" if ($paragraph_open);
            $level = 1 if ($level < 1);
            $level = 6 if ($level > 6);
            print $ofh "<h$level>$title</h$level>\n\n";
            undef $paragraph_open;
        }
        elsif ($line =~ /^\s*$/)
        {
            print $ofh "</p>\n\n" if ($paragraph_open);
            undef $paragraph_open;
        }
        else
        {
            if ($paragraph_open)
            {
                print $ofh "<br />\n";
            }
            else
            {
                print $ofh "<p>";
                $paragraph_open = 1;
            }
            
            $line =~ s/\&/&amp;/g;
            $line =~ s/\</&lt;/g;
            $line =~ s/\</&gt;/g;
            $line =~ s/\*(\w.*?\w)\*/<b>$1<\/b>/g;
            
            print $ofh $line;
        }
    }
    print $ofh "</p>\n\n" if ($paragraph_open);
    print $ofh <<EOF;
</body>
</html>
EOF

}
