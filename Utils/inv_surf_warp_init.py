#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 22 16:45:29 2022

@author: lmarcos
"""

import nibabel as nib

def inv_surf_warp_init(warp,fout):
    
    gii = nib.load(warp)
    gii.darrays[0].data = -gii.darrays[0].data
    nib.gifti.write(gii,fout)