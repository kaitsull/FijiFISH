# THIS IS A PRIVATE, UNPUBLISHED REPOSITORY, PLEASE CONTACT KAITLIN FOR ACCESS AND CREDIT!

HiPlex Menu *v3.5.5*
================  
### AUTHOR: [KAITLIN SULLIVAN](https://github.com/kaitsull) (UBC) _2019-Present_    
  
*FIJI dropdown menu for mFISH registration, segmentation, and
quantification.*   

![](data/happyhip.png)  

  
  
-   🔧 [INSTALLATION](#installation) *(for your local computer ONLY)*
    -   [Permanent](#permanent)
    -   [Temporary](#temporary)
-   📂 [FILE CONVENTIONS](#file-conventions)  
    -   [ROIs](#rois)  
    -   [Image Files](#image-files)  
-   🔬 [IMAGE ANALYSIS](#image-analysis)  
    -   [Automated Run](#automated-run)  
    -   [Registration](#registration)  
    -   [Segmentation](#segmentation)  
    -   [Quantification](#quantification)  
    -   [Single Channel Quantification](#single-channel-quantification)
    -   [HiPlex Overlay](#hiplex-overlay)  
-   📊 [DATA ANALYSIS](#data-analysis)     
-   🐛 [BUGS AND ISSUES](#bugs-and-issues)  
  
## Installation  
  A note to UBC TeamShare users:  
  Skip installation and use the TeamShare app **DO NOT CHANGE OR ALTER THE TEAMSHARE APP!**    
    
  ![](https://github.com/cembrowskilab/HiPlexMenu/blob/main/data/fiji.png)
  
### Permanent  
*This installation ensures each time you open up FIJI the menu is already installed. To update you will simply replace the existing code with the new version.*   
1.  Copy the raw contents of the [latest version](https://github.com/cembrowskilab/HiPlexMenu/blob/main/HiplexMenu_v4.ijm) of the menu  
2.  Open your FIJI app  
3.  *Plug-ins* -> *Macros* -> *Startup Macros*  
4.  Paste the code at the very bottom of the StartupMacros.txt  
5.  Download LUT files and put in the FIJI lut folder (only if you want to use the HiPlex Overlay function)  
6.  Close and restart your FIJI app  
7.  You will now see the happy hippocampus icon in your FIJI!
  
### Temporary  
*This installation is useful for using the menu when on shared computers or read-only versions of FIJI. You will need to re-install the macro each time you open a new FIJI session.*  
1.  Save the [latest version](https://github.com/cembrowskilab/HiPlexMenu/blob/main/HiPlexMenu3-5-5.ijm) of the menu as a `.ijm` file  
2.  Open your FIJI app  
3.  From the top menu select: *Plug-ins* -> *Macros* -> *Install*  
4.  Select `HiplexMenu_v4.ijm` from wherever you have it saved  
5.  You will now see the happy hippocampus icon in your FIJI for the remainder of your session. 
6.  HiPlex Overlay currently does not work on read-only versions of FIJI   


## File Conventions  
### ROIs  
Tips for smooth image analysis:
- Save ROI for first round on the microscope and use re-load it for subsequent rounds (differences in polygons may affect nonlinear registration)  
- Ensure same zoom and resolution across rounds  
- Be wary of high laser intensities (autofluorescence will affect automated thresholding)  

### Image Files  
Files used in the FIJI app **must be**:  
- `.tif` files  
- `8-bit` images  
- Scaled in **microns**  
- Named as such: **R#_XXX_Genename** (eg: `R1_405_DAPI`)
    - #= the imaging round number
    - XXX= the fluorophore excitation wavelength    
- Files from *all rounds* must be saved in the same file folder   
    
*Example file folder for analysis...*  
![](https://github.com/cembrowskilab/HiPlexMenu/blob/main/data/max.png)

*Example output file folder structure __after analysis is complete__...*  
├── `max`
   └── `crop`
        └── `regImages`
          ├── `composite` DAPI overlays from registration
          └── `nonLinear`
              ├── `analyzedImages` binarized images with ROIs
              ├── `analyzedTables` tables for [RUHi](https://github.com/cembrowskilab/RUHi)
              ├── `correctedImages` images with background correction
              └── `overlay` binarized images


# Image Analysis  
 
## `Registration`  
This option takes the original images and registers them together based on their DAPI expression.  
  
 **TO RUN:**
 -    Drag-and-drop `R1_405_DAPI.tif` into FIJI and select `Registration`.  
   
 **WHAT HAPPENS:**  
 - Images will have maximum intensity projections taken and saved in a `max` folder   
 - Images will be croped to be the same size and saved in a `crop` folder   
    - Automatic Cropping: puts a box in the upper left corner of each image (auto-choice for `Automated Run`)  
    - Manual Cropping: allows one to move the location of the box (**be careful not to change the size of the box or move it form the limits however**)  
 - Images will be linearly registered to eachother and saved in a `regImages` folder    
 - Images will be nonlinearly registered to eachother and saved in a `nonLinear` folder  

## `Segmentation`  
This option takes the registered DAPI images from the `nonLinear` folder and segments them.  
The DAPI from each round will be binarized then multiplied by eachother to remove cells from out-of-focus planes.

**TO RUN:**    
-   Drag-and-drop `R1_405_DAPI.tif_registered.tif_NL.tif` from the `nonLinear` folder into FIJI and select `Segmentation`.  

*Run from the `nonLinear` folder...*  
├── `max`
   └── `crop`
        └── `regImages`
          ├── `composite`
          └── `nonLinear`__<- drag DAPI file from this folder***__


**WHAT HAPPENS: **    
-   Segmentation Type: _select DAPI_    
    -    Segment based on DAPI signal from every round (to ensure registration in the z-axis)  
    -    If there is a round where DAPI is not segmentable, uncheck it
-   Threshold Type: _binarize the images for segmentation_      
    -    Automatic Thresholding  
    -    Manual Thresholding: (select threshold manually with a slider if some DAPI rounds look strange via Automatic Thresholding) 
-   Dialation Value: _dilate ROIs to include the surrounding cytosol_  
    -    Suggested Value = `3 microns`  
    -    For densly packed regions or nuclear expression only, change value to `0 microns`  
      
-   Segmented image is saved in an `analyzedImages` folder
-   Segmented ROIs are saved in `analyzedTables` folder      
  
  
## `Quantification`  
This option takes individual gene expression images from the `nonLinear` folder and quantifies their expression into tables saved in the `analyzedTables` folder.  

*Run from the `nonLinear` folder...* 
├── `max`
   └── `crop`
        └── `regImages`
          ├── `composite`
          └── `nonLinear` __<- Drag _first channel_ from this folder***__
              └── `analyzedTables`
              
  
**TO RUN:**  
-   Drag-and-drop your first gene image from the `nonLinear` folder into FIJI and select `Quantification` from the menu  
  
  
**WHAT HAPPENS:**   
-   **NEW:** `Perfusion` prompt will show up. This is under construction, select **Yes** unless working with __human__ or __embryonic__ tissue.  
-   `Automatic thresholding` will take the provided tail of the image's cumulative histogram via *MaxEntropy*    
-   `Manual thresholding` allows one to manually select the threshold for each image (*useful in cases of autofluorescence*)  

**OUTPUT:**  
-   Quantified tables for [`RUHi`](https://github.com/cembrowskilab/RUHi) analysis in `analyzedTables` folder` 
-   Quantified image overlays for quality control in the `analyzedImages` folder  
  

## `Single Channel Quantification`  
This option allows one to manually threshold and quantify a single channel that may not look exactly right with automated thresholding.  
  
Simply drag-and-drop your image from the `nonLinear` folder and run this option to manually threshold. This will overwrite the original quantified table in the `analyzedTables` folder.   

## `HiPlex Overlay`  
This option creates a representative overlay image of your binarized gene expression images. 

1. Download the `.lut` files from [here](https://github.com/cembrowskilab/HiPlexMenu/tree/main/luts) 
2. Place them in the FIJI `lut` folder
3. Re-start Fiji
  
  
**TO RUN:**
-   Drag-and-drop your first gene image from the `overlay` folder into FIJI and select `HiPlex Overlay` from the menu  

**WHAT HAPPENS:**  
-   When running, images will be opaquely overlaid and the order and colours of the images will print out in the `Log` box.  
  
**OUTPUT:**  
-   The image will save in the `overlay` folder as `TestCOMP.png`.  
-   **In the future, there will be an option to change the colours and order of overlay images**  
  
   
-   To **create a manual overlay image**: pseudocolour according to prefered image colours and and use FIJI's `Image` -> `Overlay...` -> `Add Image` with zero background checked!

## `Automated Run`  
  
**It is suggested to only use AutoRun once you are comfortable with each individual analysis step**  
This option runs a full analysis from `Registration` -> `Segmentation -> `Quantification` without many pauses for options.
It will automatically: crop, segment, and quantify - there will be no option to choose.  
  
**TO RUN:**    
-   simply drag and drop `R1_405_DAPI.tif` into FIJI and select `Automated Run`.  
  
**OUTPUT:**    
-   All files and folders generated from `Registration`, `Segmentation`, `Quantification`, and `HiPlex Overlay`  

  
# Data Analysis  
See the [RUHi Package](https://github.com/cembrowskilab/RUHi) for how to: visualize, dimensionally reduce, and cluster this data!  

# Bugs and Issues  
Take a screenshot of the Log, the Debug Window, and any other relevant info or messages and open up an issue - I will try and get to it as soon as I can 😺!




