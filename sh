#!/bin/bash

# ---------- Database Menu (inside a connected DB) ----------
db_menu() {
    while true; do
        choice=$(yad --width=400 --height=350 --title="DB Menu" \
            --list --radiolist --column="Select" --column="Option" \
            FALSE "Create Table" \
            FALSE "List Tables" \
            FALSE "Drop Table" \
            FALSE "Insert into Table" \
            FALSE "Select From Table" \
            FALSE "Delete From Table" \
            FALSE "Update Table" \
            FALSE "Back to Main Menu" \
            --separator=":")

        # Extract only the option text (2nd field)
        choice=$(echo "$choice" | awk -F':' '{print $2}')

        case $choice in
            "Create Table")
                tname=$(yad --entry --title="Create Table" --text="Enter table name:")
                if [ -f "$tname.meta" ]; then
                    yad --info --text="Table already exists."
                else
                    col_count=$(yad --entry --title="Columns" --text="Enter number of columns:")
                    cols=()
                    types=()
                    for ((i=1; i<=col_count; i++)); do
                        col_name=$(yad --entry --title="Column $i" --text="Enter column name:")
                        col_type=$(yad --entry --title="Column $i" --text="Enter datatype for $col_name (int/string):")
                        cols+=("$col_name")
                        types+=("$col_type")
                    done
                    pk=$(yad --entry --title="Primary Key" --text="Columns: ${cols[*]} \nEnter primary key column:")

                    echo "${cols[*]}" | tr ' ' '|' > "$tname.meta"
                    echo "${types[*]}" | tr ' ' '|' >> "$tname.meta"
                    echo "$pk" >> "$tname.meta"
                    touch "$tname.data"

                    yad --info --text="Table '$tname' created successfully!"
                fi
                ;;

            "List Tables")
                tables=$(ls *.meta 2>/dev/null | sed 's/.meta$//')
                if [ -z "$tables" ]; then
                    yad --info --text="No tables found."
                else
                    yad --info --text="Tables:\n$tables"
                fi
                ;;

            "Drop Table")
                tname=$(yad --entry --title="Drop Table" --text="Enter table name:")
                if [ -f "$tname.meta" ]; then
                    rm -f "$tname.meta" "$tname.data"
                    yad --info --text="Table '$tname' dropped successfully."
                else
                    yad --error --text="Table does not exist."
                fi
                ;;

            "Insert into Table")
                tname=$(yad --entry --title="Insert" --text="Enter table name:")
                if [ ! -f "$tname.meta" ]; then
                    yad --error --text="Table does not exist."
                else
                    IFS='|' read -r -a cols < "$tname.meta"
                    IFS='|' read -r -a types < <(sed -n '2p' "$tname.meta")
                    pk=$(sed -n '3p' "$tname.meta")

                    row=()
                    for i in "${!cols[@]}"; do
                        col_name="${cols[$i]}"
                        col_type="${types[$i]}"
                        while true; do
                            value=$(yad --entry --title="Insert" --text="Enter value for $col_name ($col_type):")

                            if [[ "$col_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                                yad --error --text="Invalid int."
                                continue
                            elif [[ "$col_type" == "string" && ! "$value" =~ ^[A-Za-z]*$ ]]; then
                                yad --error --text="Invalid string."
                                continue
                            fi

                            if [ "$col_name" == "$pk" ]; then
                                if cut -d'|' -f$((i+1)) "$tname.data" | grep -qx "$value"; then
                                    yad --error --text="Duplicate primary key."
                                    continue
                                fi
                            fi
                            row+=("$value")
                            break
                        done
                    done

                    (IFS='|'; echo "${row[*]}" >> "$tname.data")
                    yad --info --text="Row inserted into '$tname'."
                fi
                ;;

            "Select From Table")
                tname=$(yad --entry --title="Select" --text="Enter table name:")
                if [[ -f "$tname.data" && -f "$tname.meta" ]]; then
                    IFS="|" read -r -a cols < "$tname.meta"
                    rows=$(awk -F'|' '{printf "%s\n", $0}' "$tname.data")
                    yad --text-info --title="Table: $tname" --filename=<(echo -e "Columns: ${cols[*]}\n\n$rows")
                else
                    yad --error --text="Table does not exist."
                fi
                ;;

            "Delete From Table")
                tname=$(yad --entry --title="Delete" --text="Enter table name:")
                if [[ -f "$tname.data" && -f "$tname.meta" ]]; then
                    IFS="|" read -r -a cols < "$tname.meta"
                    colname=$(yad --entry --title="Delete" --text="Available columns: ${cols[*]} \nEnter column name:")
                    col_index=-1
                    for i in "${!cols[@]}"; do
                        [[ "${cols[$i]}" == "$colname" ]] && col_index=$i && break
                    done
                    if [[ $col_index -eq -1 ]]; then
                        yad --error --text="Column not found."
                    else
                        val=$(yad --entry --title="Delete" --text="Enter value to delete:")
                        tmpfile=$(mktemp)
                        while IFS="|" read -r -a row; do
                            [[ "${row[$col_index]}" != "$val" ]] && echo "${row[*]}" | tr ' ' '|'
                        done < "$tname.data" > "$tmpfile"
                        mv "$tmpfile" "$tname.data"
                        yad --info --text="Rows deleted successfully."
                    fi
                else
                    yad --error --text="Table does not exist."
                fi
                ;;

            "Update Table")
                tname=$(yad --entry --title="Update" --text="Enter table name:")
                if [[ -f "$tname.data" && -f "$tname.meta" ]]; then
                    IFS="|" read -r -a cols < "$tname.meta"
                    IFS="|" read -r -a types < <(sed -n '2p' "$tname.meta")

                    cond_col=$(yad --entry --title="Update" --text="Available columns: ${cols[*]} \nEnter condition column:")
                    cond_index=-1
                    for i in "${!cols[@]}"; do
                        [[ "${cols[$i]}" == "$cond_col" ]] && cond_index=$i && break
                    done
                    [[ $cond_index -eq -1 ]] && yad --error --text="Condition column not found." && continue
                    cond_val=$(yad --entry --title="Update" --text="Enter value to match:")

                    upd_col=$(yad --entry --title="Update" --text="Enter column to update:")
                    upd_index=-1
                    for i in "${!cols[@]}"; do
                        [[ "${cols[$i]}" == "$upd_col" ]] && upd_index=$i && break
                    done
                    [[ $upd_index -eq -1 ]] && yad --error --text="Update column not found." && continue

                    new_val=$(yad --entry --title="Update" --text="Enter new value:")
                    col_type="${types[$upd_index]}"
                    if [[ "$col_type" == "int" && ! "$new_val" =~ ^-?[0-9]+$ ]]; then
                        yad --error --text="Invalid integer."
                        continue
                    elif [[ "$col_type" == "string" && ! "$new_val" =~ ^[A-Za-z]*$ ]]; then
                        yad --error --text="Invalid string."
                        continue
                    fi

                    tmpfile=$(mktemp)
                    while IFS="|" read -r -a row; do
                        if [[ "${row[$cond_index]}" == "$cond_val" ]]; then
                            row[$upd_index]="$new_val"
                        fi
                        echo "${row[*]}" | tr ' ' '|'
                    done < "$tname.data" > "$tmpfile"
                    mv "$tmpfile" "$tname.data"
                    yad --info --text="Update successful."
                else
                    yad --error --text="Table does not exist."
                fi
                ;;

            "Back to Main Menu")
                return
                ;;
        esac
    done
}

# ---------- Main Menu ----------
while true; do
    choice=$(yad --width=400 --height=300 --title="Main Menu" \
        --list --radiolist --column="Select" --column="Option" \
        FALSE "Create Database" \
        FALSE "List Databases" \
        FALSE "Connect to Database" \
        FALSE "Drop Database" \
        FALSE "Exit" \
        --separator=":")

    # Extract only option text
    choice=$(echo "$choice" | awk -F':' '{print $2}')

    case $choice in
        "Create Database")
            dbname=$(yad --entry --title="Create DB" --text="Enter database name:")
            mkdir "$dbname"
            yad --info --text="Database created."
            ;;
        "List Databases")
            dblist=$(ls -d */ 2>/dev/null)
            yad --info --text="Databases:\n$dblist"
            ;;
        "Connect to Database")
            dbname=$(yad --entry --title="Connect" --text="Enter DB name:")
            if [ -d "$dbname" ]; then
                cd "$dbname"
                yad --info --text="Connected to $dbname"
                db_menu
                cd ..
            else
                yad --error --text="Database does not exist."
            fi
            ;;
        "Drop Database")
            dbname=$(yad --entry --title="Drop DB" --text="Enter DB name:")
            if [ -d "$dbname" ]; then
                rm -r "$dbname"
                yad --info --text="Database dropped."
            else
                yad --error --text="Database does not exist."
            fi
            ;;
        "Exit")
            exit 0
            ;;
    esac
done

