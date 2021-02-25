# Change file names
#
# This script allows changing filenames and/or remove spaces in a folder
# Select the folder with the files, put the original string you want to replace by new string
# leave them empty if you just want to remove spaces
# Select Remove spaces option if you want to remove spaces
# Example: If you want to change the name of the file teste 1.tif by teste01.tif put
#                original string = 1, new string = 01 and select remove spaces options
#
#
# Requires python 3.6, PySimpleGUI (to install run 'python -m pip install pysimplegui' in a cmd window)
#
#
# This macro should NOT be redistributed without author's permission. 
# Explicit acknowledgement to the ALM facility should be done in case of published articles 
# (approved in C.E. 7/17/2017):     
# 
# "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
# member of the national infrastructure PPBI-Portuguese Platform of BioImaging 
# (supported by POCI-01-0145-FEDER-022122)."
# 
# Date: February/2021
# Author: Mafalda Sousa, mafsousa@ibmc.up.pt
# Advanced Ligth Microscopy, I3S 
# PPBI-Portuguese Platform of BioImaging


import os, sys 
import PySimpleGUI as sg

sg.change_look_and_feel('Dark2') 

file_list_column = [
    [
        sg.Text("Input Folder"),
        sg.In(size=(25, 1), enable_events=True, key="-FOLDER-"),
        sg.FolderBrowse(),
    ],
    [
        sg.Text(text='Original string'), sg.InputText('', size=(10, 1), key='-input_original-'),
        sg.Text(text='New string'), sg.InputText('', size=(10, 1), key='-input_new-')
    ],
    [
        sg.Checkbox('Remove spaces',key ='-spaces-', enable_events=True, size=(12, 1), default=True)
    ],
    [
        sg.Button('Ok'), sg.Button('Cancel')
    ]
]
layout = [
    [
        sg.Column(file_list_column)       
    ]
]

# Create the window
window = sg.Window("Change file names", layout)

# Create an event loop
while True:
    event, values = window.read()
    if event == sg.WIN_CLOSED or event == 'Cancel': # if user closes window or clicks cancel
        window.close()
        sys.exit(0)
    elif event == 'Ok':
        break

window.close()
path = values['-FOLDER-']
for filename in os.listdir(path):    
    f = filename.replace(values['-input_original-'], values['-input_new-'])
    if (values['-spaces-'] == True):
        s = f.replace(" ", "")
    else:
        s = f
    print("File changed to ", s)
    os.rename(path + os.path.sep + filename, path + os.path.sep+ s)
    

