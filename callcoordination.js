var currentSequence;

function loadFormation(sequence, formation)
{
    var currentSequence = sequence;
    var formation_text = '';
    var pos = sequences[sequence].formations[formation];

    var elements = document.getElementsByClassName('squareDanceCall');
    for (var i = 0; i < elements.length; ++i)
    {
        var e = elements.item(i)
        console.log("Looking at element " + e);
        e.classList.remove('currentCall');
    }

    console.log("Looking for call"+formation);
    document.getElementById("call" + formation).classList.add('currentCall');

    for (var count = 0; count < pos.length; ++count)
    {
        formation_text += pos[count] + "\n";
    }
    document.getElementById("formation_view").innerHTML = formation_text;
}

function goToRelativeCall(n)
{
    var re = /call(\d+)/;
    var currentCalls = document.getElementsByClassName('currentCall');
    var index = 0;

    for (var i = 0; i < currentCalls.length; ++i)
    {
        var call = currentCalls.item(i)
        var id = call.getAttribute('id');
        if (id)
        {
            index = id.replace(re, "$1");
            index = parseInt(index) + n;
        }
    }
    if (document.getElementById("call" + index) )
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
    console.log("Loading sequence " + sequence);
    document.getElementById("sequence_title").innerHTML = sequences[sequence].description;
    var currentSequences = document.getElementsByClassName('currentSequence');
    for (var i = 0; i < currentSequences.length; ++i)
    {
        var e = currentSequences.item(i);
        console.log("Removing currentSequence from " + i);
        e.classList.remove('currentSequence');
    }
    console.log("Setting current sequence to " + sequence);
    document.getElementById("sequenceSpan" + sequence).classList.add('currentSequence');

    moves = '<li>' + sequences[sequence].opening + '</li>';
    for (call = 0; call < sequences[sequence].moves.length; ++call)
    {
        moves += '<li class="squareDanceCall" id="call'+(call+1)
            + '"><a onClick="loadFormation('
            + sequence + ',' + (call + 1) + ')">'
            + sequences[sequence].moves[call] + '</a></li>';
    }
    moves += '<li class="squareDanceCall" id="resolution">'
          + sequences[sequence].resolve + '</li>';
    document.getElementById("sequence").innerHTML = moves;
    loadFormation(sequence,1);
}

    function displayFormations()
    {
        var s = document.getElementById('search').style;
        s.visibility='hidden';
        var t = document.getElementById('formations').style;
        t.visibility='visible'
    }

    function displaySearch()
    {
        var s = document.getElementById('formations').style;
        s.visibility='hidden';
        var t = document.getElementById('search').style;
        t.visibility='visible'
    }

list = '';
for  (counter = 0; counter < sequences.length; counter++)
    list += '<li><a  id="sequenceButton' + counter +'" onClick="loadSequence(' + counter + ');"><span id="sequenceSpan' + counter +'">' + sequences[counter].description + '</span></a></li>';
document.getElementById("call_list").innerHTML = list;
document.getElementById("nextCallButton").addEventListener("touchstart", goToNextCall, false);
document.getElementById("previousCallButton").addEventListener("touchstart", goToPreviousCall, false);

displayFormations();
