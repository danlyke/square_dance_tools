Just a place to stash square dance tools.

The first one, rewrite_for_sd.pl, takes the files generated by
http://www.challengedance.org/sd/ and feeds them back into that tool,
generating formation pictures for every move. It then creates HTML for
use on a tablet as a calling aid.

Usage:

* Put rewriteforsd.pl in the same directory as sdtty.

* Run sdtty, enter a level ("Plus"), if it asks for it enter "0" for no session.

* Do a simple sequence (ie: "heads start", "square thru 4"), then do
  "write this sequence", give the sequence a name, and "exit".

* Run rewriteforsd.pl on the resulting file, ie:

  rewriteforsd ./sequence.Plus

* This will create a /var/www/squaredancehelper/sequence.html that has
  your sequences in it.


