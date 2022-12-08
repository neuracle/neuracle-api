
# !/usr/bin/env python3
# -*- coding:utf-8 -*-

# Versions:
# 	v0.1: 2018-08-14, orignal

# Author: FANG Junying, fangjunying@neuracle.cn
# Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/

from neuracle_lib.readbdfdata import readbdfdata
from tkinter import filedialog
from tkinter import *
import numpy as np
import os

def check_files_format(path):
     filename = []
     pathname = []
     if len(path) == 0:
          raise TypeError('please select valid file')

     elif len(path) == 1:
          (temppathname, tempfilename) = os.path.split(path[0])
          if 'edf' in tempfilename:
               filename.append(tempfilename)
               pathname.append(temppathname)
               return filename, pathname
          elif 'bdf' in tempfilename:
               raise TypeError('unsupport only one neuracle-bdf file')
          else:
               raise TypeError('not support such file format')

     else:
          temp = []
          temppathname = r''
          evtfile = []
          idx = np.zeros((len(path) - 1,))
          for i, ele in enumerate(path):
               (temppathname, tempfilename) = os.path.split(ele)
               if 'data' in tempfilename:
                    temp.append(tempfilename)
                    if len(tempfilename.split('.')) > 2:
                         try:
                              idx[i] = (int(tempfilename.split('.')[1]))
                         except:
                              raise TypeError('no such kind file')
                    else:
                         idx[i] = 0
               elif 'evt' in tempfilename:
                    evtfile.append(tempfilename)

          pathname.append(temppathname)
          datafile = [temp[i] for i in np.argsort(idx)]

          if len(evtfile) == 0:
               raise TypeError('not found evt.bdf file')

          if len(datafile) == 0:
               raise TypeError('not found data.bdf file')
          elif len(datafile) > 1:
               print('current readbdfdata() only support continue one data.bdf ')
               return filename, pathname
          else:
               filename.append(datafile[0])
               filename.append(evtfile[0])
               return filename, pathname

if __name__ == '__main__':

     root = Tk()
     root.withdraw()
     ## select bdf or edf file
     path = filedialog.askopenfilenames(initialdir='/', title='Select two bdf files',
                                        filetypes=(("two bdf files", "*.bdf"), ("one edf files", "*.edf")))
     ## check files format
     filename, pathname = check_files_format(path)
     ## parse data
     eeg = readbdfdata(filename,pathname)
     print(eeg)

