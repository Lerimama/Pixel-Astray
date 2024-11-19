
free error

# CHNG ... change dis
# ime kolumne ... je povsode kjer je treba menjat, če bo drugo ime
# ime tabele ... je povsode kjer je treba menjat, če bo drugo ime

# helper function to get sheet by name, change the id with your id or you can also pass it as parameter 
function getSheet(sheet_name) {

  # CHNG <---
  # ... tole lahko setaš tudi getByUrl in je avtomatizirano kot za samo tabelo getSheetByName
  var spreadsheet = SpreadsheetApp.openById('1TGv_ZhSLEJarNo10oS2FjeHGTkeXbM1auV3Vf-r1vlo');  
  # -------->

  return spreadsheet.getSheetByName(sheet_name);
}


# READ/WRITE funkciji ----------------------------------------------------------------------------------------


# parameters so parametri, ki jih dosegam z urljem (kot gugl search ... www.google.com/q?="hello", ki da


function doGet(e) {
  var action = e.parameter.action;
  
  switch (action) {
    case 'fetch_notes_list': 
      return fetchNotesList();
    case 'fetch_notes_content':
      return fetchNotesContent(e.parameter.id);
    default:
      return ContentService.createTextOutput("Invalid action");
  }
}


function doPost(e) {
  var action = e.parameter.action;
  
  switch (action) {
    case 'create_new_note':
      return createNewNote(e.postData.contents);
    case 'save_existing_note':
      return saveExistingNote(e.postData.contents);
    case 'delete_note':
      return deleteNote(e.postData.contents);
    default:
      return ContentService.createTextOutput("Invalid action");
  }
}


# POST ... WRITE ------------------------------------------------------------------------------------------------------


# createNewNote
# saveExistingNote


function createNewNote(data) { # data ...  pošljem table title
	
  # CHNG <--- ime tabele 
  var sheet = getSheet('data'); # ime tabele se nahaja v zavihku tabele
  # verzija z aktivno tabelo
  ## var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet(); #  ... tabelo lahko kličeš tudi po imenu ... če jih je več getSheetByName recimo
  # -------->

 # parse to json
  var jsonData = JSON.parse(data);

  # kreiram nov uniq id
  var id = getNextId(sheet); 

  # CHNG <--- ime kolumne
  var title = jsonData.title;
  var text = jsonData.text;
  # -------->
  
  # preverjam polnost polj
  if (!title || !text) { # ... ime kolumne
    return ContentService.createTextOutput("Title and text are required");
  }

  # add new row
  sheet.appendRow([id, title, text]); # ... ime kolumne 
  return ContentService.createTextOutput("New note created with ID: " + id);

}


function saveExistingNote(data) { # podobno kot zgornja, samo da moram najt ID in range polnih polj

  # CHNG <--- ime tabele 
  var sheet = getSheet('data');
  ## var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet(); #  ... tabelo lahko kličeš tudi po imenu ... če jih je več getSheetByName recimo
  # -------->

  # parse to json
  var jsonData = JSON.parse(data);
  
  # kreiram nov uniq id
  var id = parseInt(jsonData.id, 10);

  # CHNG <--- ime kolumne 
  var title = jsonData.title;
  var text = jsonData.text;
  # -------->
  
  # preverim polnost polj, če ne bo delal v prazno
  if (!id || !title || !text) {  # ... ime kolumne
    return ContentService.createTextOutput("ID, title, and text are required");
  }
  
  # get range pomembno! ... getRange(row_no , column_no)
  # sheet.getRange(row number 1, column number 1, row number 2, column number 2, ...);
  var range = sheet.getRange(2, 1, sheet.getLastRow() - 1, 3); // trenuten zapis je tak, ker imamo v prvi kolumni ID
  var values = range.getValues();
  
  # grebam podatke
  for (var i = 0; i < values.length; i++) {
    if (values[i][0] === id) { # ime kolumne ... tole ni najboljši način, ampak najhitrejši za implementacijio(lahko bi naredil tudi filter funkcijo
      sheet.getRange(i + 2, 2).setValue(title); # Update title ... ime kolumne
      sheet.getRange(i + 2, 3).setValue(text); # Update text ... ime kolumne
      return ContentService.createTextOutput("Note with ID " + id + " updated."); # ime kolumne
    }
  }
  return ContentService.createTextOutput("Note with ID " + id + " not found."); # ime kolumne
}


# GET ... READ ------------------------------------------------------------------------------------------------------


# fetchNotesList --> ko imaš veliko podatkov in podaš najprej listo naslovov, potem pa na klik poiščeš določeno vsebino
# fetchNotesContent --> točno določena vsebina
# deleteNote


function fetchNotesList() {
	
  # CHNG <--- ime tabele 
  var sheet = getSheet('data');
  ## var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet(); #  ... tabelo lahko kličeš tudi po imenu ... če jih je več getSheetByName recimo
  # -------->
  

  var range = sheet.getRange(2, 1, sheet.getLastRow() - 1, 2);  // Get ID and Title columns
  var values = range.getValues();
  var notesList = [];
  
  for (var i = 0; i < values.length; i++) {
    notesList.push({ id: values[i][0], title: values[i][1] }); # ... ime kolumne
  }
  
  # parse to json
  return ContentService.createTextOutput(JSON.stringify(notesList))
    .setMimeType(ContentService.MimeType.JSON);
}


function fetchNotesContent(id) { # ime kolumne
	
  # CHNG <--- ime tabele 
  ## var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet(); #  ... tabelo lahko kličeš tudi po imenu ... če jih je več getSheetByName recimo
  var sheet = getSheet('data');
  # -------->

  var noteId = parseInt(id, 10); # ime kolumne
  
  # preverjam polnost polj 
  if (!noteId) { 
    return ContentService.createTextOutput("ID is required");
  }
  
  # get range ... enako kot POST
  var range = sheet.getRange(2, 1, sheet.getLastRow() - 1, 3);
  var values = range.getValues();
  
  for (var i = 0; i < values.length; i++) {
    if (values[i][0] === noteId) {
      var note = { id: values[i][0], title: values[i][1], text: values[i][2] }; # ... ime kolumne
      return ContentService.createTextOutput(JSON.stringify(note))
	.setMimeType(ContentService.MimeType.JSON);
    }
  }
  return ContentService.createTextOutput("Note with ID " + noteId + " not found.");
}


function deleteNote(data) {
  # CHNG <--- ime tabele 
  var sheet = getSheet('data');
  ## var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet(); #  ... tabelo lahko kličeš tudi po imenu ... če jih je več getSheetByName recimo
  # -------->

  var jsonData = JSON.parse(data);
  var id = parseInt(jsonData.id, 10); # ime kolumne
  
  # preverjam polnost polj
  if (!id) { # ime kolumne
    return ContentService.createTextOutput("ID is required");
  }
  
  var range = sheet.getRange(2, 1, sheet.getLastRow() - 1, 3);
  var values = range.getValues();
  
  # Delete the row with the matching ID
  for (var i = 0; i < values.length; i++) {
    if (values[i][0] === id) { # ime kolumne
      sheet.deleteRow(i + 2);
      return ContentService.createTextOutput("Note with ID " + id + " deleted."); # ime kolumne
    }
  }
  return ContentService.createTextOutput("Note with ID " + id + " not found."); # ime kolumne
}


# id novega noteta ... helper function
function getNextId(sheet) { 
  var lastRow = sheet.getLastRow();
  if (lastRow === 1) return 1;  // No data yet
  
  var lastId = sheet.getRange(lastRow, 1).getValue();
  return lastId + 1;
}

