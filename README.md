HiPlex Menu *v3.5.0*
================  
##### BY: KAITLIN SULLIVAN (UBC)    
  
*FIJI dropdown menu for mFISH registration, segmentation, and
quantification.*   

![](data/happyhip.png)
  
  
-   🔧 [INSTALLATION](#installation) 
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

# Image Analysis  
*HiPlex Menu Options...*  
![](https://github.com/cembrowskilab/HiPlexMenu/blob/main/data/hiplex%20menu.png)  
  
## `Automated Run`  
This option runs a full analysis from `Registration` -> `Segmentation -> `Quantification` with pauses for options (detailed further below) 
  
**TO RUN:**    
-   simply drag and drop `R1_405_DAPI.tif` into FIJI and select `Automated Run`.  
  
**OUTPUT:**    
-   All files and folders generated from `Registration`, `Segmentation`, `Quantification`, and `HiPlex Overlay`  
  
## `Registration`  
This option takes the original images and registers them together by DAPI expression.  
  
 **TO RUN:**
 -    Drag-and-drop `R1_405_DAPI.tif` into FIJI and select `Registration`.  
   
 **WHAT HAPPENS:**  
 - Images will have maximum intensity projections taken and saved in a `max folder`  
 - Images will be croped to be the same size and saved in a `crop folder`  
    - Automatic Cropping: puts a box in the upper left corner of each image (auto-choice for `Automated Run`)  
    - Manual Cropping: allows one to move the location of the box (**be careful not to change the size of the box or move it form the limits however**)  
 - Images will be linearly registered to eachother and saved in a `regImages folder`    
 - Images will be nonlinearly registered to eachother and saved in a `nonLinear folder`  

## `Segmentation`  
This option takes the registered DAPI images from the `nonLinear folder` and segments them.  

**TO RUN:**    
-   Drag-and-drop `R1_405_DAPI.tif_registered.tif_NL.tif` from the `nonLinear folder` into FIJI and select `Segmentation`.  

**WHAT HAPPENS: **    
-   Segmentation Type:  
    -    Segment based on DAPI signal from every round (to ensure registration in the z-axis)  
    -    Segment only Round 1 (not recommended)  
-   Threshold Type:  
    -     Automatic Thresholding  
    -     Manual Thresholding (select threshold manually with a slider if some DAPI rounds look strange via Automatic Thresholding)    
-   Segmented image is saved in an `analyzedImages folder`      
  
  
## `Quantification`  
This option takes individual gene expression images from the `nonLinear folder` and quantifies their expression into tables saved in the `analyzedTables folder`.  
  
**TO RUN:**  
-   Drag-and-drop your first gene image from the `nonLinear folder` into FIJI and select `Quantification` from the menu  
  
  
**WHAT HAPPENS:** 
-   `Automatic thresholding` will take the provided tail of the image's cumulative histogram  
-   `Manual thresholding` allows one to manually select the threshold for each image (*useful in cases of autofluorescence*)  

**OUTPUT:**  
-   Quantified tables for [`RUHi`]() analysis in `analyzedTables folder`  
-   Quantified image overlays for quality control in the `analyzedImages folder`  
  

## `Single Channel Quantification`  
This option allows one to manually threshold and quantify a single channel that may not look exactly right with automated thresholding.  
  
Simply drag-and-drop your image from the `nonLinear folder` and run this option to manually threshold. This will overwrite the original quantified table in the `analyzedTables folder`.  

## `HiPlex Overlay`  
This option creates a representative overlay image of your binarized gene expression images.  
  
  
**TO RUN:**
-   Drag-and-drop your first gene image from the `overlay folder` into FIJI and select `HiPlex Overlay` from the menu  

**WHAT HAPPENS:**  
-   When running, images will be opaquely overlaid and the order and colours of the images will print out in the `Log` box.  
  
**OUTPUT:**  
-   The image will save in the `overlay` folder as `TestCOMP.png`.  
-   **In the future, there will be an option to change the colours and order of overlay images**  
  
   
-   To create a manual overlay image: pseudocolour according to prefered image colours and and use FIJI's `Image` -> `Overlay...` -> `Add Image`

  
# Data Analysis  
See the [RUHi Package](https://github.com/cembrowskilab/RUHi) for how to: visualize, dimensionally reduce, and cluster this data

# Bugs and Issues  
Take a screenshot of any error messages or debug windows you get and send them to *Kaitlin* (or open up an issue in the repo) 😺  




