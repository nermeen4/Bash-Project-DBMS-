# 🗄️ Bash Shell Database Management System (DBMS)

## 📘 Overview
This project is a **Command-Line Interface (CLI)** and **Graphical User Interface (GUI)** based Database Management System built entirely using **Bash scripting**.  
It simulates the behavior of a simple DBMS — allowing users to create, manage, and manipulate databases and tables directly from the terminal or through a GUI (using **YAD**).

The project was developed as part of a Bash scripting learning journey and demonstrates how file operations, loops, arrays, and condition handling in Bash can mimic database operations.

---

## ⚙️ Features

### 🧩 CLI Version (`tst`)
- Create and list databases
- Connect to a database
- Drop databases
- Create tables with columns and datatypes
- Set a **Primary Key** column
- Insert, Select, Delete, and Update table records
- Validate input types (`int` or `string`)
- Enforce primary key uniqueness
- Data and metadata stored in files:
  - `table_name.meta` → stores schema (columns, types, PK)
  - `table_name.data` → stores actual data

### 🪟 GUI Version (YAD)
- User-friendly dialogs for interaction
- Error messages, confirmations, and input forms displayed with `yad`
- Replicates all CLI operations visually

---

## 🧠 Project Structure

bash project/
│
├── tst # Main CLI script
├── gui_version.sh # GUI version (YAD-based)
└── sample_databases/ # Folder created automatically when running the script


When you create a database, a folder is made under the current directory.  
Each database folder contains:
database_name/
├── table_name.meta
└── table_name.data



---

## 🧰 Technologies Used
- **Bash Scripting**
- **YAD (Yet Another Dialog)** for GUI
- **Linux File System** for storage simulation

---

## 🚀 How to Run

### 🖥️ Run CLI Version
1. Open your terminal.
2. Navigate to your project directory:
   ```bash
   cd ~/bash\ project

Give execution permission:
chmod +x tst

Run the script:
./tst

You’ll see a main menu like this:
1) Create Database
2) List Databases
3) Connect to Database
4) Drop Database
5) Exit

Once you connect to a database, another menu will appear for table operations
1) Create Table
2) List Tables
3) Drop Table
4) Insert into Table
5) Select From Table
6) Delete From Table
7) Update Table
8) Back to Main Menu


Run the GUI Version:
Make sure YAD is installed:
sudo apt install yad


🧑‍💻 Author

Nermeen Magdy & Mohamed Mokhtar
💡 A Bash-based DBMS project demonstrating how scripting can simulate database behavior.
Developed as part of a learning journey to strengthen Linux and shell scripting skills.
