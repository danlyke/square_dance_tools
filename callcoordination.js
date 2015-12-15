var currentSequence;

function loadFormation(sequence, formation)
{
  currentSequence = sequence;
  formation_text = '';
  pos = sequences[sequence].formations[formation];

  $('.squareDanceCall').removeClass('currentCall');
  $("#call" + formation).addClass('currentCall');

  for (count = 0; count < pos.length; ++count)
  {
     formation_text += pos[count] + "\n";
  }
  $("#formation_view").html(formation_text);
}

function goToRelativeCall(n)
{
   var re = /call(\d+)/;
   id = $(".currentCall").attr('id');
   index = id.replace(re, "$1");
   index = parseInt(index) + n;
   if ($("#call" + index).length )
   {
      loadFormation(currentSequence, index);
   }
}

function goToNextCall()
{
  goToRelativeCall(1);
}

function goToPreviousCall()
{
  goToRelativeCall(-1);
}


function loadSequence(sequence)
{
   $("#sequence_title").html(sequences[sequence].description);
   moves = '<li>' + sequences[sequence].opening + '</li>';
   for (call = 0; call < sequences[sequence].moves.length; ++call)
   {
      moves += '<li class="squareDanceCall currentCall" id="call'+(call+1)
          + '"><a onClick="loadFormation('
          + sequence + ',' + (call + 1) + ')">'
          + sequences[sequence].moves[call] + '</a></li>';
   }
   $("#sequence").html(moves);
}

$(document).ready(function() {
    list = '';
    for  (counter = 0; counter < sequences.length; counter++)
        list += '<li><a onClick="loadSequence(' + counter + ');">' + sequences[counter].description + '</a></li>';
    $("#call_list").html(list);
    $('#search').hide();
});
