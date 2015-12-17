var currentSequence;

function loadFormation(sequence, formation)
{
    currentSequence = sequence;
    formation_text = '';
    pos = sequences[sequence].formations[formation];

    elements = document.getElementsByClassName('squareDanceCall');
    for (i = 0; i < elements.length; ++i)
    {
        e = elements.item(i)
        console.log("Looking at element " + e);
        e.classList.remove('currentCall');
    }

    console.log("Looking for call"+formation);
    document.getElementById("call" + formation).classList.add('currentCall');

    for (count = 0; count < pos.length; ++count)
    {
        formation_text += pos[count] + "\n";
    }
    document.getElementById("formation_view").innerHTML = formation_text;
}

function goToRelativeCall(n)
{
    var re = /call(\d+)/;
    currentCalls = document.getElementsByClassName('currentCall');
    var index = 0;

    for (i = 0; i < currentCalls.length; ++i)
    {
        call = currentCalls.item(i)
        id = call.getAttribute('id');
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
    document.getElementById("sequence_title").innerHTML = sequences[sequence].description;
    moves = '<li>' + sequences[sequence].opening + '</li>';
    for (call = 0; call < sequences[sequence].moves.length; ++call)
    {
        moves += '<li class="squareDanceCall" id="call'+(call+1)
            + '"><a onClick="loadFormation('
            + sequence + ',' + (call + 1) + ')">'
            + sequences[sequence].moves[call] + '</a></li>';
    }
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
    list += '<li><a onClick="loadSequence(' + counter + ');">' + sequences[counter].description + '</a></li>';
document.getElementById("call_list").innerHTML = list;
displaySearch();
