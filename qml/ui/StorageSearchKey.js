  function getDatabase() {
       return LocalStorage.openDatabaseSync("searchkeys_db", "1.0", "StorageDatabase", 1000000);
  }

  function createTables() {

      var db = getDatabase();

      db.transaction(
          function(tx) {
              tx.executeSql('CREATE TABLE IF NOT EXISTS storedKeys(key_id INTEGER PRIMARY KEY AUTOINCREMENT, key_word TEXT)');
      });
  }

  function insertKeyData(keyword, size){

    var db = getDatabase();

    var res = [];
    
    var found = false;
    
    var inserted = false;
    
    var maxDBsize = 21;
    
    var keywordTrim = keyword.trim();
    
    var i = 0;
    
    while (found == false & i<size) {
      var output = getValueFromStr(i, keywordTrim);
      if (output == 1) {
        found = true;
      }
      i = i + 1;
    }
    
    if (found == false) {

          db.transaction(function(tx) {
        
              var rs = tx.executeSql('INSERT INTO storedKeys(key_word) VALUES (?);', [keywordTrim]);
              inserted = true;
          }
          );
    }
    if (size + 1 == maxDBsize & inserted) {
      var deleteKey = getValueFromPos(0);
      deleteKeyword(deleteKey);
    }
  }

  function getSize(){

        var db = getDatabase();

        var rs = "";

        db.transaction(function(tx) {
              rs = tx.executeSql("SELECT key_id FROM storedKeys t where t.key_id");
            }
        );

        if (rs.rows.length > 0) {
          return rs.rows.length;
        } else {
            return 0;
        }
   }
   
   function getValueFromStr(position, text){

         var db = getDatabase();

         var rs = "";

         db.transaction(function(tx) {
             rs = tx.executeSql("SELECT key_word FROM storedKeys t where t.key_id");
             }
         );

         if (rs.rows.length > 0) {
             var row = position;
             var checkStr = text.toLowerCase();
             var targetStr = rs.rows.item(row).key_word;
             targetStr = targetStr.toLowerCase();
             if (checkStr == targetStr) {
               return 1;
             } else {
               return 0;
             }
         } else {
             return -1;
         }
    }
    
       function deleteKeyword(nameKey){

         var db = getDatabase();
         var res = "";

         var rs = "";

         db.transaction(function(tx) {
          rs = tx.executeSql("DELETE FROM storedKeys WHERE key_word = ?", [nameKey]);
             }
         );

    }
   

   function getValueFromPos(position){

         var db = getDatabase();

         var rs = "";

         db.transaction(function(tx) {
             rs = tx.executeSql("SELECT key_word FROM storedKeys t where t.key_id");
             }
         );

         if (rs.rows.length > 0) {
             var row = position;
             return rs.rows.item(row).key_word;
         } else {
             return 0;
         }
    }


    function doesExistKeyStorage(){
      createTables();
      var db = getDatabase();
      var rs = "";

      db.transaction(function(tx) {
         rs = tx.executeSql("SELECT t.key_id FROM storedKeys t where t.key_id");
          }
      );

      if (rs.rows.length == 0) {
        return 0;
      } else {
        return 1;
      }
    }