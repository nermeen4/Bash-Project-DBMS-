#!/bin/bash

# table_menu
db_menu() {
    PS3="DB Menu > Enter your choice: "
    select ch in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Back to Main Menu"
    do
        case $REPLY in

		#Create table
            1) read -p "Enter table name: " tname
               if [ -f "$tname.meta" ]; then
                   echo "Table already exists."
               else
                   read -p "Enter number of columns: " col_count
                   cols=()
                   types=()
                     
		   #meta file(sechma)
                   for ((i=1; i<=col_count; i++)); do
                        read -p "Enter name of column $i: " col_name

			# keep asking until valid datatype
                        while true; do
                            read -p "Enter datatype of $col_name (int/string): " col_type
                            if [[ "$col_type" == "int" || "$col_type" == "string" ]]; then
                                 break
                            else
                              echo "Invalid input. Please type 'int' or 'string'."
                            fi
                        done

                        cols+=("$col_name")
                        types+=("$col_type")
                   done

                   # Ask for Primary Key
                   echo "Columns: ${cols[*]}"
                   read -p "Enter column name to set as Primary Key: " pk

                   # Save metadata
                   echo "${cols[*]}" | tr ' ' '|' > "$tname.meta"
                   echo "${types[*]}" | tr ' ' '|' >> "$tname.meta"
                   echo "$pk" >> "$tname.meta"

                   # Create empty data file
                   touch "$tname.data"

                   echo "Table '$tname' created successfully!"
               fi ;;

            2) 
		    #List tables
               echo "Tables in database:"
               if ls *.meta 1> /dev/null 2>&1; then #hide output/error of system
                   for t in *.meta; do
                        echo " - ${t%.meta}" #remove extention .meta
                   done
               else
                   echo " (no tables found)"
               fi;;

            3)
	          #Drop table	   
               echo "Available tables:"
               shopt -s nullglob
               tables=(*.meta)

               if [ ${#tables[@]} -eq 0 ]; then
                  echo " (no tables to drop)"
               else
                  for t in "${tables[@]}"; do
                       echo " - ${t%.meta}"
                  done
                  read -p "Enter the table name you want to drop: " tname
                  if [ -f "$tname.meta" ]; then
                       rm -f "$tname.meta" "$tname.data"
                       echo "Table '$tname' dropped successfully."
                  else
                      echo "Table '$tname' does not exist."
                  fi
	       fi;;


            4) 
		    #Insert into table
	       echo "Available tables:"
	       shopt -s nullglob    #prevent tables("*.meta")instead of null 
               tables=(*.meta)

               if [ ${#tables[@]} -eq 0 ]; then
                  echo " (no tables available)"
               else
                  for t in "${tables[@]}"; do
                       echo " - ${t%.meta}"
                  done
                  read -p "Enter table name to insert into: " tname

                  if [ ! -f "$tname.meta" ]; then
                      echo "Table '$tname' does not exist."
                  else
                      # Read metadata
                      IFS='|' read -r -a cols < "$tname.meta"       
                      IFS='|' read -r -a types < <(sed -n '2p' "$tname.meta") 
                      pk=$(sed -n '3p' "$tname.meta")             

                      row=()
                      for i in "${!cols[@]}"; do
                          col_name="${cols[$i]}"
                          col_type="${types[$i]}"

                          while true; do
                              read -p "Enter value for $col_name ($col_type): " value
                              # Type check
                              if [[ "$col_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                                  echo "Invalid int. Try again."
                                  continue
                              elif [[ "$col_type" == "string" && ! "$value" =~ ^[A-Za-z]+$ ]]; then
                                  echo "Invalid string. Try again."
                                  continue                              
			      fi
                              # Primary key check
                              if [ "$col_name" == "$pk" ]; then
                                  if cut -d'|' -f$((i+1)) "$tname.data" | grep -qx "$value"; then #extract values of pk column from file.data then compare with the value u insert for uniqueness
                                       echo "Duplicate primary key '$value'. Try again."
                                       continue
                                   fi
                               fi
                               row+=("$value")
                               break
                          done
                      done

                      # Save row
                      (IFS='|'; echo "${row[*]}" >> "$tname.data")
                      echo "Row inserted into '$tname'."
                  fi
               fi;;


            5)
		    #Select from table
              read -p "Enter table name to select from: " tname
              if [[ -f "$tname.data" && -f "$tname.meta" ]]; then
                   # Read header (columns)
		   IFS="|" read -r -a cols < "$tname.meta"  # read first line in .meta (column names) into cols arr.
                   echo "------------------------------------"
                   echo "Table: $tname"
                   echo "Columns: ${cols[*]}"
                   echo "------------------------------------"

		   if [[ -s "$tname.data" ]]; then  # (-s) check if there is data or not

                       # Print rows nicely
                       while IFS="|" read -r -a row; do
                          for ((i=0; i<${#cols[@]}; i++)); do
				  
                               printf "%-15s" "${row[i]}"   # make space between values in each column around 15char.
                          done
                          echo
                       done < "$tname.data"  #read data in loop 
                   else
                       echo "(no rows found)"
                   fi
                   echo "------------------------------------"
              else
                 echo "Table does not exist."
              fi;;

            6)
		    #Delete from table
              read -p "Enter table name to delete from: " tname
              if [[ -f "$tname.data" && -f "$tname.meta" ]]; then
                  # Read column names
                  IFS="|" read -r -a cols < "$tname.meta"

                  echo "Available columns: ${cols[*]}"
                  read -p "Enter column name to match for deletion: " colname
       
                  # Find column index
                  col_index=-1
                  for i in "${!cols[@]}"; do
                      if [[ "${cols[$i]}" == "$colname" ]]; then
                          col_index=$i
                          break
                      fi
                  done

                  if [[ $col_index -eq -1 ]]; then
                      echo "Column not found."
                  else
                      read -p "Enter value to delete (rows where $colname = value): " val
           
                      # Delete rows matching value in that column
                      tmpfile=$(mktemp)  #temporary file to void corrupting the original file while we are still processing it.
                      while IFS="|" read -r -a row; do
                          if [[ "${row[$col_index]}" != "$val" ]]; then  #check if the value u in is not u want to delete, so keep it in that tempfile
                              echo "${row[*]}" | tr ' ' '|'
                          fi
                      done < "$tname.data" > "$tmpfile"

                      mv "$tmpfile" "$tname.data"
                      echo "Rows deleted successfully."
                  fi
              else
                 echo "Table does not exist."
              fi;;

            7)
		    #Update in table
              read -p "Enter table name to update: " tname
              if [[ -f "$tname.data" && -f "$tname.meta" ]]; then
                  # Read column names & types
                  IFS="|" read -r -a cols < "$tname.meta"
                  IFS="|" read -r -a types < <(sed -n '2p' "$tname.meta")

                  echo "Available columns: ${cols[*]}"

                  # Condition: which row(s) to update
                  read -p "Enter column name to match: " cond_col
                  cond_index=-1
                  for i in "${!cols[@]}"; do
                      if [[ "${cols[$i]}" == "$cond_col" ]]; then
                          cond_index=$i
                          break
                      fi
                  done
                  if [[ $cond_index -eq -1 ]]; then
                      echo "Condition column not found."
                      continue
                  fi
                  read -p "Enter value to match in $cond_col: " cond_val

                  # Update target column
                  read -p "Enter column name to update: " upd_col
                  upd_index=-1
                  for i in "${!cols[@]}"; do
                      if [[ "${cols[$i]}" == "$upd_col" ]]; then
                          upd_index=$i
                          break
                      fi
                  done
                  if [[ $upd_index -eq -1 ]]; then
                      echo "Update column not found."
                      continue
                  fi

                  # Loop for new value until valid
		  while true; do 
                      read -p "Enter new value for $upd_col: " new_val

                      # Validate datatype
                      col_type="${types[$upd_index]}"
                      if [[ "$col_type" == "int" && ! "$new_val" =~ ^-?[0-9]+$ ]]; then 
                           echo "Invalid integer."
                           continue
                      elif [[ "$col_type" == "string" && ! "$new_val" =~ ^[A-Za-z]*$ ]]; then
                           echo "Invalid string."
                           continue
                      fi
		      break
		  done

                  # Rewrite file
                  tmpfile=$(mktemp)
                  while IFS="|" read -r -a row; do
                      if [[ "${row[$cond_index]}" == "$cond_val" ]]; then
                          row[$upd_index]="$new_val"
                      fi
                      echo "${row[*]}" | tr ' ' '|'
                  done < "$tname.data" > "$tmpfile"

                  mv "$tmpfile" "$tname.data"
                  echo "Update successful."
              else
                  echo "Table does not exist."
              fi;;

            8)
              echo "Returning to Main Menu..."
              return;; # to end function db_menu

            *) echo "Invalid choice." ;;
        esac
	REPLY=   #to reset REPLY value.
    done
}

# main menu
PS3="Enter your choice:"
select ch in "Create Database" "List Databases" "Connect to Database" "Drop Database" "Exit"
do
     case $REPLY in
                  1)read -p "Enter the name of db:" dbname
                    mkdir "$dbname"
                    echo "Database created."
                    ;;

                  2)echo "list all database."
                    ls -d */
                    ;;

                  3)read -p "Enter db u want to connect." dbname
                    if [ -d "$dbname" ]; then
                        cd "$dbname"
                        echo "connected successfully to $dbname."
			db_menu
			cd ..
                    else
                        echo "Database doesn't exist."
                    fi;;

                  4)read -p "Enter db to drop." dbname
                    if [ -d "$dbname" ]; then
                       rm -r "$dbname"
                       echo "Database dropped"
                   else
                       echo "Database doesn't exist."
                   fi;;

                  5)exit;;

                  *)echo "Invalid choice.";;


      esac
      REPLY=   #to reset REPLY value.

done

