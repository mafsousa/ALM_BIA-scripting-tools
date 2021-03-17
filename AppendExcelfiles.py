## Append excel files
## Version:v0.1
##
## Short description: Input similar (same columns) excel files, the output directory and the output file name.
## The script will append excel files with the same columns and save one excel file with the result 
##  
## Requires python 3.8, pysimplegui ('python -m pip install pysimplegui') and pandas (python -m pip install pandas)
## 
## This script should NOT be redistributed without author's permission. 
## Explicit acknowledgement to the ALM facility should be done in case of published articles (approved in C.E. 7/17/2017):     
## 
## "The authors acknowledge the support of i3S Scientific Platform Advanced Light Microscopy, 
## member of the national infrastructure PPBI-Portuguese Platform of BioImaging (supported by POCI-01-0145-FEDER-022122)."
## 
## Date: March/2021
## Author: Mafalda Sousa, mafsousa@ibmc.up.pt 
## Advanced Ligth Microscopy, I3S 
## PPBI-Portuguese Platform of BioImaging
##


import PySimpleGUI as sg
import pandas as pd
import os,sys, ntpath
from tkinter import * #available only on python >3.7
from tkinter.filedialog import askopenfilename


def path_leaf(path):
    head, tail = ntpath.split(path)
    return tail or ntpath.basename(head)

# create GUI
sg.change_look_and_feel('Dark2') 

file_list_column = [
    [        
        sg.Text("Select excel files to merge"),
        sg.Button('Browse', key='-BROWSE-')
    ],   
    [
        sg.Multiline(size=(50, 10), enable_events=True, font=('Courier', 9),key='-FILE LIST-'),

    ],
    [
        sg.Text("Output folder"),
        sg.In(size=(50, 1), enable_events=False, key="_FOLDER_"),
        sg.FolderBrowse()
    ],
    [
        sg.Text("Output file name"),
        sg.In(size=(25, 1), enable_events=True, key="_FILE_"),
    ],
    [
        sg.Button('Merge'), sg.Button('Cancel'),
    ]
]
layout = [
    [
        sg.Column(file_list_column)       
    ]
]

window = sg.Window("Merge excel files", layout)

# Create an event loop
while True:
    event, values = window.read()
    if event == sg.WIN_CLOSED or event == 'Cancel': # if user closes window or clicks cancel
        window.close()
        sys.exit(0)
    elif event == 'Merge':
        break   
    elif event == '-BROWSE-':
        files = filedialog.askopenfilenames(initialdir="/", title='Please select fileS')  
        filenames = [path_leaf(f) for f in files]
        window['-FILE LIST-'].update("\n".join(filenames))
    
window.close()


# Read all three files into pandas dataframes
all_files = {}
i= 0
for file in files:    
    all_files[i] = pd.read_excel(file)
    i = i +1

# Merge all the dataframes in all_df_list
# Pandas will automatically append based on similar column names
appended_df = pd.concat(all_files)

# Write the appended dataframe to an excel file
# Add index=False parameter to not include row numbers
appended_df.to_excel(values['_FOLDER_'] + os.path.sep + values['_FILE_'] + ".xlsx", index=False)

print('==Files merged at ',  values['_FOLDER_'] + os.path.sep + values['_FILE_'] + ".xlsx==")


