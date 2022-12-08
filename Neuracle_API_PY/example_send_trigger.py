#! /usr/bin/env python  
#  -*- coding:utf-8 -*-
#
# Author: FANG Junying, fangjunying@neuracle.cn
#
# Versions:
# 	v0.1: 2020-02-25, orignal
#
# Copyright (c) 2020 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/

from neuracle_lib.triggerBox import TriggerBox,TriggerIn,PackageSensorPara
import time
# from psychopy import  visual, event,core


if __name__ == '__main__':
    isTriggerIn = True
    isTriggerBox = False

    if isTriggerIn:
        ## example send triggers through TriggerIn
        triggerin = TriggerIn("COM3")
        flag = triggerin.validate_device()
        if flag:
            for i in range(1, 10):
                triggerin.output_event_data(i)
                time.sleep(1)
        else:
            raise Exception("Invalid Serial!")

    if isTriggerBox:
        ## example send triggers by TriggerBox
        triggerbox = TriggerBox("COM3")
        for i in range(1,10):
            print('send trigger: {0}'.format(i))
            triggerbox.output_event_data(i)
            time.sleep(1)
