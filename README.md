HiPlex Menu *v3.0.0*
================  

*FIJI dropdown menu for mFISH registration, segmentation, and
quantification.*  

![](data/happyhip.png)
  
  
-   [INSTALLATION](#installation) 
    -   [Permanent](#permanent)
    -   [Temporary](#temporary)
-   [FILE CONVENTIONS](#file-conventions)  
    -   [ROIs](#rois)  
    -   [Image Files](#image-files)  
-   [IMAGE ANALYSIS](#image-analysis)  
    -   [Automated Run](#automated-run)  
    -   [Registration](#registration)  
    -   [Segmentation](#segmentation)  
    -   [Quantification](#quantification)  
    -   [Single Channel Quantification](#single-channel-quantification)
    -   [HiPlex Overlay](#hiplex-overlay)  
-   [BUGS AND ISSUES](#bugs-and-issues)  
  

## Installation  
  
  ![](https://github.com/cembrowskilab/HiPlexMenu/blob/main/data/fiji.png)
  
### Permanent  
*This installation ensures each time you open up FIJI the menu is already installed. To update you will simply replace the existing code with the new version.*   
1.  Copy the raw contents of the [latest version](https://github.com/cembrowskilab/HiPlexMenu/blob/main/Menu_v3-0-0.ijm) of the menu  
2.  Open your FIJI app  
3.  *Plug-ins* -> *Macros* -> *Startup Macros*  
4.  Paste the code at the very bottom of the StartupMacros.txt  
5.  Close and restart your FIJI app  
6.  You will now see the happy hippocampus icon in your FIJI!
  
### Temporary  
*This installation is useful for using the menu when on shared computers or read-only versions of FIJI. You will need to re-install the macro each time you open a new FIJI session.*  
1.  Save the [latest version]() of the menu as a `.ijm` file  
2.  Open your FIJI app  
3.  From the top menu select: *Plug-ins* -> *Macros* -> *Install*  
4.  Select `Menu_v3-0-0.ijm` from wherever you have it saved  
5.  You will now see the happy hippocampus icon in your FIJI for the remainder of your session. 


## File Conventions  
### ROIs  
Tips for smooth image analysis:
- Save ROI for first round and use for subsequent rounds (differences in polygons may affect nonlinear registration)  
- Ensure same zoom and resolution across rounds  
- Be wary of high laser intensities (autofluorescence will affect automated thresholding)  

### Image Files  
Files used in the FIJI app **must be**:  
- `.tif` files  
- Named as such: **R%_XXX_genename**
    - % = the imaging round number
    - XXX = the fluorophore excitation wavelength  
- Files from *all rounds* must be saved in the same file folder   
    
*Example file folder for analysis...*  
![](https://github.com/cembrowskilab/HiPlexMenu/blob/main/data/max.png)

## Image Analysis  
*HiPlex Menu Options...*  
![](https://github.com/cembrowskilab/HiPlexMenu/blob/main/data/hiplex%20menu.png)  
  
### Automated Run  

  

## Bugs and Issues  





