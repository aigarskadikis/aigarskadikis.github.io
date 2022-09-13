var dlgArea = document.getElementById("searchResultDlg");
var searchInput = document.getElementById("searchInput");
var searchResultDlgContent = document.getElementById("searchResultDlgContent");
var dataArray = [];

function initDataArray(){
    var allNodes = document.getElementsByTagName("code");
    
    for(var i = 0; i < allNodes.length; i++){
        if (allNodes[i].parentElement.localName == "pre"){
            dataArray[i] = [allNodes[i].parentElement.previousSibling.nodeValue.trim(), allNodes[i].innerHTML, allNodes[i].parentElement.parentElement.previousElementSibling.innerHTML];
        }
    }

}


function searchAndDisplay(value){
    var indexToDisplay = [];
    for (var i in dataArray){
        if(dataArray[i][0].indexOf(value) != -1 || dataArray[i][1].indexOf(value) != -1){
            indexToDisplay.push(i);
        }
    }

    if(indexToDisplay.length == 0){
        searchResultDlgContent.innerHTML = "There is no matched data to display :(";
        return;
    }

    var finalOutput = "";
    for (var j in indexToDisplay){
        var tempOutput = "";
        tempOutput = "<div class='resultBlock'><div class='tabName'>" + dataArray[indexToDisplay[j]][2] + "</div><div class='title'>" + dataArray[indexToDisplay[j]][0] + "</div><div class='content'><pre><code>" + dataArray[indexToDisplay[j]][1] + "</code></pre></div></div>";
        finalOutput += tempOutput;
    }

    searchResultDlgContent.innerHTML = finalOutput;
}


function onCloseDlg() {
  dlgArea.style.display = "none";
  searchInput.value = "";
}

function onTypeSearchInput(event){
    var value = searchInput.value;
    if(value.length > 0 ){
        searchAndDisplay(value);
        dlgArea.style.display = "flex";

    }else{
        dlgArea.style.display = "none";
    }
}
