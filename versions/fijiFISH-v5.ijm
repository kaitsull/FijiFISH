
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
//																					  //
//               Kaitlin Sullivan HiPlex Plugin Script - May 2019					  //
//   				for analysis of in situ hybridization data						  //
//																					  //
//			To Install: copy and paste code into the StartupMacros.txt 				  //
//						Plugins -> Macros -> Startup Macros							  //
//																					  //
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////




/////////////////////////////////HELPER FUNCTIONS///////////////////////////////////////
//These functions are used throughout the actual dropdown menu code to 
//do common functions like find the number of rounds/channels or save files


/////////////////////////////////General Functions//////////////////////////////////////

//NUMROUND
//returns the number of imaging rounds present in data
function numRound(dir) {
	fileList = getFileList(dir);
	rnd = 0;
	//debug
	//Array.print(fileList);
	//print(rnd);
	//print(k);
	for (k = 0; k < fileList.length; k++) {
		cur = substring(fileList[k], 1, 2);
		//debug
		//print(cur);
		//print(fileList[k]);
		if(!isNaN(cur)){
			if (rnd < cur) {
				rnd = cur;
			}	
		}
	}
	if(rnd == 0){
		exit("Files in directory are improperly named or directory is empty. Ensure files named according to convention: RX_###_genename.");
	}
	else {
		rnd = parseInt(rnd);
		return rnd;
	}
}


//AUTOOPEN
//automatically opens files that start with a specified string
function autoOpen (dir, prefix){
	fileList=getFileList(dir);
	found = false;
	i=0;
	while(found != true){
		//print(fileList[i]);
		if (i >= fileList.length){
			exit("No files found. Check naming convention.");
		}
		else if (startsWith(fileList[i], prefix)&&(!endsWith(fileList[i], ".txt"))) {
			open(dir+fileList[i]);
			//print(dir+fileList[i]);
			found = true;
		}
		i++;
	}
}


//CHANNELS
//UPDATED in 2025 to remove hard-coding of 488,550,647,750!
//returns number of unique channels beyond DAPI (405) in a specified imaging round
function channels(dir, rnd) {
	//get files and instantiate the R# prefix to search for
    fileList = getFileList(dir);
    prefix = "R" + rnd + "_";
    
    rc = newArray(0); // empty array
    
    for (i = 0; i < fileList.length; i++) {
        if (startsWith(fileList[i], prefix)) {
            rest = substring(fileList[i], prefix.length); // ex: "488_Gnb4...tif"
            idx = indexOf(rest, "_");
            if (idx >= 0) {
                sub = substring(rest, 0, idx); // ex: "488"
                if (sub != "405") {
                    // check for uniqueness without indexOf done with help of GPT 4
                    found = false;
                    for (j = 0; j < rc.length; j++) {
                        if (rc[j] == sub) {
                            found = true;
                            break;
                        }
                    }
                    // Add on that new channel to the array
                    if (!found) {
                        rc = Array.concat(rc, newArray(sub));
                    }
                }
            }
        }
    }
    return rc;
}

/////////////////////////////////Registration Functions//////////////////////////////////////
 
//TRANSLATE
//translates the image via input x,y coordinates
function translate(x, y) {
      run("Select All");
      run("Cut");
      makeRectangle(x, y, getWidth(), getHeight());
      run("Paste");
      run("Select None");
}

//SLICE - Depreceated due to thin z stacks and increased computation times associated with max projections
//makes a slice through the z axis via a diagonal line in x,y
function slice(img, name){
	selectImage(img);
	makeLine(0, 0, getWidth(), getHeight());
	run("Reslice [/]...", "output=1 slice_count=1");
	rename(name);
}

//SIZEUP
//Check for size of images across rounds
function sizeUp(dir) { 
	rnd = numRound(dir);
	fileList = getFileList(dir);
	widths = newArray(rnd);
	heights = newArray(rnd);
	same = true;
	
	//open DAPI rounds and save the heights and widths
	for (i = 1; i <= rnd; i++) {
		nm = "R" + i + "_405";
		print("Opening image: " + nm + "...");
		autoOpen(dir, nm);
		
		widths[i-1] = getWidth();
		heights[i-1] = getHeight();

		//check to see if width and height are the same across rounds
		if (i>1) {
			if ((widths[i-1] != widths[i-2]) |(heights[i-1] != heights[i-2])) {
			same = false;
			}
		}
		close();
	}

	if(!same){
	//sort the arrays 
	widths = Array.sort(widths);
	heights = Array.sort(heights);
	
	//return values for cropping
	c = newArray(widths[0], heights[0]);
	return c;
	}
	else {
		c = newArray(0);
		return c;
	}
}

//CROP
//crops an image
function crop(width, height){
	makeRectangle(0, 0, width, height);
	run("Crop");
}

//MAKEWINDOW
//takes an image and creates a window with width and height as a power of 2 for FFT
function makeWindow(img, name, z){
	
	selectImage(img);
	h = getHeight();
	w = getWidth();
	pwr= 4;
	size = false;
	if(h>w){
		side = w;
	}
	if(w>h){
		side = h;
	}

	while(!size){
		if(pow(2, pwr)>side){
			pwr=pow(2, (pwr-1));
			size=true;
		}
		else{
			pwr++;
		}	
	}

	if(z == 0){
		x = ((w/2)-(pwr/2));
		y = ((h/2)-(pwr/2));
	}

	else{
		x = ((w/z)-(pwr/2));
		y = ((h/z)-(pwr/2));
	}

	makeRectangle(x, y, pwr, pwr);
	run("Copy");
	newImage(name, "8-bit black", pwr, pwr, 1);
	run("Paste");
	run("Select None");
}

//BATCHSPLIT
//batch open and merge files across rounds (hiplex only)
//kaitlin change 2025
function batchSplit(newDir, rnd, nms) { 
	
	setBatchMode(true);
	print("Splitting and saving channels from Round " + rnd + "...");
	run("Split Channels");
	ch = newArray(nms.length);
	for (i = 0; i < nms.length; i++) {
		ch[i] = "C" + (i+1);
	}
	
	if(isOpen("Composite")){
	close("Composite");
	}
	
	//autoopen and save names
	for (i = 0; i < ch.length; i++) {
		//substring name of split composite
		convention = getTitle();
		title = substring(convention, 2, lengthOf(convention));
		id = ch[i] + title;
		selectWindow(id);
		path = newDir + nms[i];
		saveAs("Tiff", path);
		close(nms[i]);
		print("Saved: " + nms[i]);
	}
	
	setBatchMode(false);
}

//BATCHMERGE
//combine images to be maxproj/cropped (hiplex only)
//return an array of names
//kaitlin change 2025
function batchMerge(dir, rnd) { 
	print("Opening and merging channels from Round "+ rnd +"...");
	setBatchMode("hide");
//save number of channels to be used to merge
//kaitlin change 2025
	chan = channels(dir, rnd); //number of unique channels per round
	Array.print(chan);
	mer = newArray(chan.length + 1);

//autoopen dapi image if not present
	if(nImages == 0){
		pref = "R" + rnd + "_405";
		autoOpen(dir, pref);
	}
	mer[0] = getTitle();
	print(mer[0]);
	
	//autoopen and save names
	for (i = 0; i < chan.length; i++) {
		pref = "R" + rnd + "_" + chan[i];
		autoOpen(dir, pref);
		mer[i+1] = getTitle(); 
		print(mer[i+1]);
	}
	
	//merge channels - hard coded to 3-5
	if(chan.length == 4){
		//sort the array of names to match Fiji's channel ordering convention
		sorted = newArray(mer[4], mer[2], mer[0], mer[1], mer[3]);
		run("Merge Channels...", "c1=" + mer[4] + " c2=" + mer[2]+ " c3=" + mer[0] + " c5=" + mer[1] + " c7=" + mer[3] + " create");
	}
	else if(chan.length == 3){
		//sort the array of names to match Fiji's channel ordering convention
		sorted = newArray(mer[2], mer[0], mer[1], mer[3]);
		run("Merge Channels...", "c2=" + mer[2]+ " c3=" + mer[0] + " c5=" + mer[1] + " c7=" + mer[3] + " create");
	}
	else{
		//sort the array of names to match Fiji's channel ordering convention
		sorted = newArray(mer[2], mer[0], mer[1]);
		run("Merge Channels...", "c2=" + mer[2]+ " c3=" + mer[0] + " c5=" + mer[1] + " create");
	}
	
	setBatchMode(false);
	
	
	//return array with names
	return sorted;
}

//DAPIMERGE
//open and merge/overlay DAPI across rounds for rigid and elastic registration
function dapiMerge(dir, nl){	
	//instantiate an array to include names of dapi images
	rnd = numRound(dir);
	nms = newArray(rnd);
	setBatchMode("hide");
	
	//open images
	for (i = 1; i <= rnd; i++) {
		if(nl)
			pref = "R" + i + "_405_DAPI.tif_registered.tif_NL.tif";
		else 
			pref = "R" + i + "_405_DAPI.tif";
		autoOpen(dir,pref);
		nms[i-1] = getTitle();
	}
	//overlay if more than 7 channels
	if (nImages>7) {
		for (i = 1; i < rnd; i++) {
			selectImage(nms[0]);
			run("Add Image...", "image="+nms[i]+" x=0 y=0 opacity=50 zero");
		}
	}
	//merge if 7 or less channels
	else{
		str = "";
		for (i = 1; i <= rnd; i++) {
			//create string of channels to pass through merge
			str = str + "c" + i + "=" + nms[i-1] + " ";
		}
		run("Merge Channels...", str + " create ignore");
	}
	setBatchMode("exit and display");
}




/////////////////////////////////Quantification Functions//////////////////////////////////////

//HISTPERCENTILE
//Select a threshold via finding the tail end of a normalized cumulative histogram
function histPercentile(img, percent){
	//ensure correct window is active image
	selectWindow(img);
	
	//get the histogram of the image
	getHistogram(values, counts, 256);
	nBins = 256;

	//get the cumulative histogram by adding up consecutive bin values
	cHist = newArray(nBins);
	cHist[0] = counts[0];
	for (i = 1; i < nBins; i++) {
		cHist[i] = counts[i] + cHist[i-1];
	}

	//normalize by dividing each bin value by the final bin value of the cumulative histogram
	ncHist = newArray(nBins);
	for (i = 0; i < nBins; i++) {
		ncHist[i] = cHist[i]/cHist[nBins-1];
	}

	//find the 99th percentile
	bin = 0;
	thresh = 0;

	//99th percentile is saved as thresh -> the value to be returned and set as the threshold for the image
	while (ncHist[bin] <= percent) {
		thresh = ncHist[bin];
		bin++;
	}
	
	//return the bin number with 99th percentile
	return(bin);
}

//QUANT *****ALTERED FUNCTION UPDATE DOCUMENTATION
//quantifies image (by image ID) either automatically (c>=1) or individually (c = 0)
function quant(img, dir, c, sg, type){
	
	//convert to 8bit
	run("8-bit");

	//save the directories for registered and unregistered images
	regDir = dir;
	rdL = lengthOf(regDir);
	dir = substring(regDir, 0, rdL-10);

	//750 channels - require smoothing due to poor signal-to-noise
	if (substring(img, 3, 6) == "750") {
		run("Smooth");
	}
	
	//SINGLE CHANNEL
	if(c == 0){
		//threshold and wait for user response
		setAutoThreshold(type + " dark");
		run("Threshold...");
		waitForUser("Adjust the threshold slider & APPLY. Then, press OK in this window. \n Compare to autothreshold by selecting method: MaxEntropy or Triangle"); 
	}
	
	//AUTOTHRESHOLDING
	else {
		if(c >= 1){	
			//old version requiring thresh + upper from the histPercentile function
			//threshold the image
			//setThreshold(thresh, upper);
			//setOption("BlackBackground", true);

			//new version
			setAutoThreshold(type + " dark");
			
		}
	}
	run("Convert to Mask", "method=Default background=Dark black");
	
	if(!sg){
		//save a binarized image in OVERLAY folder for final composite image
		ovDir = regDir + "overlay" + File.separator;
		//print(ovDir);
		maskFile = ovDir + img;
		saveAs("Tiff", maskFile);

		//quantify the expression
		roiManager("measure");
	}
	
	close("Threshold");
	//run("Close All");
}

//SAVEFILES
//saves an image, tab, and log file for each channel to be quantified
function saveFiles(img, ovDir, imgDir, tabDir, funct){
		
	if (isNaN(ovDir)) {
		//print("Opening checkpoint #2...");
		open(ovDir + img);
		//print("Passed checkpoint #2!");
		// Save results table
		resultsFile = tabDir + name + "_" + funct + ".csv";
		saveAs("Results",resultsFile);
		run("Clear Results");
	}

	if(nSlices==1){
		// Prep images for saving
		roiManager("Show All");
		roiManager("Show All with labels");
		run("Flatten");
	
		close("\\Others");

		//print("Opening checkpoint #3...");
		toOpen = dir + img; // reopen original ISH window
		print(img);
		open(toOpen);
		//print("Passed checkpoint #3!");
		run("Images to Stack");
		stackFile = imgDir + img + "_mask.tif";
		saveAs("Tiff",stackFile);
	}
	else{
		roiManager("Show All");
		roiManager("Show All with labels");
		stackFile = imgDir + img + "_mask.tif";
		saveAs("Tiff", stackFile);
	}	
}



/////////////////////////////////////////////////////////////////////////////////////////////
//																						   //
//									HIPLEX DROPDOWN MENU								   //
//																						   //
/////////////////////////////////////////////////////////////////////////////////////////////


//menu icon + dropdown creation
var hmCmds = newMenu("HiPlex Menu Tool", 
	newArray("Automated Run...","-","Registration", "Segmentation", "Quantification", "-", "HiPlex Overlay", "Single Channel Quantification"));
macro "HiPlex Menu Tool - CfffD00D01D02D03D0dD0eD0fD10D11D12D16D17D18D19D1bD1dD1eD1fD20D21D24D25D26D28D2bD2eD2fD30D31D34D38D39D3cD3eD3fD40D41D43D45D47D48D49D4fD50D51D53D57D5aD5fD60D63D66D67D69D6cD6dD6fD70D72D73D76D78D79D7cD7fD80D83D86D87D89D8aD8fD90D91D93D95D97D99D9aD9eD9fDa0Da1Da3Da4Da7Da9DacDaeDafDb0Db1Db4Db7DbaDbcDbfDc0Dc1Dc4Dc5Dc8DcaDcdDcfDd0Dd1Dd2Dd5Dd6Dd8DdbDdfDe0De1De2De3De6De7De8De9DeeDefDf0Df1Df2Df3Df4DfcDfdDfeDffCe12D27D35D36D37D44D54D64D65D74D75D84D85D94Db5Db6Dc6Dc7Dd7C000D05D06D07D08D09D0aD0bD0cD13D14D1cD23D2cD2dD32D33D3dD42D4dD52D5eD61D62D6eD71D7eD81D82D88D8dD8eD92D98D9dDa2Da8DadDb2Db3Db9DbdDbeDc3Dc9DceDd3Dd4Dd9DdaDddDdeDe4De5DeaDebDecDedDf5Df6Df7Df8Df9DfaC36bD1aD29D2aD3aD3bD4bD4cD5cCfe1D59D6aD7aD7dD8cD9cDabDbbDcbDccDdc"{

//BUILT-IN FIJI MACROS		
		builtin = newArray("Open...", "Merge Channels...", "Channels Tool...");
		cmd = getArgument();
		if (cmd!="-"){
			if (cmd == builtin[0] || cmd == builtin[1] || cmd == builtin[2]) {
				doCommand(cmd);
			}
			else {
//AUTO RUN			
				if(cmd != "Automated Run..."){
					auto = false;
				}	
				if(cmd == "Automated Run..."){
					auto = true;
					cmd = "Registration";
				}
				
				
/////////////////////////////////////////REGISTRATION///////////////////////////////////////////////////								
// SET UP (Throw errors and create necessary variables):
				if (cmd == "Registration") {
					//throw errors for incorrect number of images
					if(nImages == 0)
						exit("No images open. Please open your first round DAPI image for registration.");
					if(nImages > 1)
						exit("Please open only the first round of DAPI imaging and close any other image windows.");	
					
					getPixelSize(unit, pixelWidth, pixelHeight);
					print(unit);

					//throw error on wrong scale
					//if(unit != "µm"){
					//	exit("Please ensure your images are scaled in microns. /n See how at: https://imagej.nih.gov/ij/docs/menus/analyze.html#scale");
					//}	

					//save directory and number of rounds present
					dir = getDirectory("image");
					rnd = numRound(dir);
					//new from kaitlin revisions 2025
					//chk 2025
					chan = channels(dir, rnd);
					nm1 = getTitle();
					
		
// STEP 1: MAX INTENSITY PROJECTION:
			//assume a single plane image
					maxp = "sp";
			//if the image is a stack - GUI will pop up for maxprojection
					if(nSlices > 1){
						maxDir = dir + "max" + File.separator;
						File.makeDirectory(maxDir);
						maxp = "max";

						for (i = 1; i <= rnd; i++) {
						//batch mode open images and merge them
							nms = batchMerge(dir, i);
							print("Creating Maximum Intensity Projection for Round" + i);
						//make max projection
							run("Z Project...", "projection=[Max Intensity]");
						//batch mode split channels and re-save cropped versions
							batchSplit(maxDir, i, nms);
						}
							//make this the main directory for future registration
						dir = maxDir;
					}
						
					//throws error if only one round (numRound also throws error if no rounds)
					if (rnd == 1) 
						exit("Registration requires 2 or more rounds of imaging. \n There is only one round of imaging present in provided directory.");
					if(!endsWith(nm1, "DAPI.tif"))
						exit("Incorrectly titled image or wrong image kind. \n Please open DAPI round 1 image: R1_405_DAPI.tif");

//STEP 2: CROPPING IMAGES:
					//images must be same size across rounds for adequate linear registration
					print("Measuring image sizes across rounds...");
					//check for the smallest size image across rounds
					cVal = sizeUp(dir);
					
					//all images must be the same width/height

			//GUI FOR AUTO OR MANUAL CROP 
					if (cVal.length != 0) {
						//create a directory to save cropped images
						cropDir = dir + "crop" + File.separator;
						File.makeDirectory(cropDir);
						
						//pop up GUI with option to autocrop or exit and manually crop
						if(!auto){
							Dialog.create("Error: Images are of different sizes! \n Would you like the macro to auto-crop each image by X = " + cVal[0] + " pixels and Y = " + cVal[1] + " pixels, \n or would you like to manually crop?");
							Dialog.addChoice("Choice: ", newArray("Auto-crop", "Manual crop"), "Auto-crop");

							Dialog.show();
							cChoice = Dialog.getChoice();
						}
						else 
							cChoice = "Auto-crop";
						
						//create a new cropping directory
						if(maxp == "max"){
								cropDir = maxDir + "crop" + File.separator;
								File.makeDirectory(cropDir);
						}

						
//2A: AUTOCROP:
						if(cChoice == "Auto-crop"){
						print(rnd);
							//for each round, batch merge, create a rectangle, then split and save
							for (i = 1; i <= rnd; i++) {
								//batch mode open images and merge them
								nms = batchMerge(dir, i);
								Array.print(nms);

								makeRectangle(0, 0, cVal[0], cVal[1]);
								
								print("Cropping images for Round " + i + "...");
								run("Crop");
								
								//batch mode split channels and re-save cropped versions
								batchSplit(cropDir, i, nms);
							}
						}

//2B: MANUAL CROP:
						if (cChoice == "Manual crop") {
							//for each round, batch merge, create a rectangle, then split and save
							for (i = 1; i <= rnd; i++) {
								//batch mode open images and merge them
								nms = batchMerge(dir, i);
								//make a box and wait for the user to drag it to the desired region
								makeRectangle(0, 0, cVal[0], cVal[1]);
								waitForUser("Manual Crop", "Drag the yellow box to the appropriate ROI for cropping and then press OK");
								
								//batch mode split channels and re-save cropped versions
								print("Cropping images for Round " + i + "...");
								run("Crop");
								batchSplit(cropDir, i, nms);
							}
						}
					//make the croping directory the new, main directory
					dir = cropDir;
					}

//STEP 3: LINEAR REGISTRATION:
			//SET UP
					//make a directory for registered + analyzed images
					regDir = dir + "regImages" + File.separator;
					File.makeDirectory(regDir)
					
				//open round 1
					autoOpen(dir, "R1_405");
					img1 = getImageID();
					nm1 = getTitle();
				//make 2^n x 2^n registration window
					makeWindow(img1, "Round1", 0);
					r1=getImageID();
				//counter for number of rounds registered
					cnt = 2;
					print("Registering in X,Y...");

				//eg array size 4 for 3 rounds
					zChange = newArray((rnd-1)*2);
					
		//3A: REGISTRATION LOOP:
					while(cnt <= rnd){
						rndNum = "R" + cnt + "_405";
						autoOpen(dir, rndNum);
						img2 = getImageID();
						nm2 = getTitle();
						makeWindow(img2, "Round2", 0);
						r2=getImageID();
						
						// cross-correlate images
						run("FD Math...", "image1=Round1 operation=Correlate image2=Round2 result=Result do");
						selectImage(r2);
						close();
						
						// write the new Image to a Results table.
						run("Image to Results");
						selectWindow("Result");
						w = getWidth(); 
						center = w/2;
						//close();

		//3B: SEARCH HIGHEST PIXEL VALUE:
					//OLD VERSION
					//Edited Oct 2022 for increase speed of analysis
						//Array to save max values - index refers to Xcoord and value refers to Ycoord
						maxVals = newArray(w);
						//Array for pixel values
						pix = newArray(w);
						//Array to save indices of Xcoords within original array
						indexMatch = newArray(w);
						for (i = 0; i < w; i++) {
							indexMatch[i] = i;
						}

						selectWindow("Results");
						//Iterate through rows
						for (i = 0; i < w; i++) {
							//Column name
							xName = "X" + i;
							xArr = Table.getColumn(xName);
							//Find Maxima
							cur = Array.findMaxima(xArr, 1);

							//Save values
							maxVals[i] = cur[0];
							pix[i] = getResult(xName, maxVals[i]);
						}

						//sort by pixel value
						Array.sort(pix, indexMatch, maxVals);

						//highest pixel value coords
						xVal = indexMatch[w-1];
						yVal = maxVals[w-1];

						//value to translate by
						xTrans = xVal-center;
						yTrans = yVal-center;
						
						run("Clear Results");

						print("Translation: X = " + xTrans + ", Y = " + yTrans);
				
	
		//3C: TRANSLATE DAPI according to xTrans and yTrans:
						selectImage(img2);
						if (maxp != "3D") {
							print("Registering in X,Y...");
							translate(xTrans, yTrans);
						}

					//save files
						regImg = regDir + nm2 + "_registered.tif";
						saveAs("Tiff",regImg);

		//3D: TRANSLATE CHANNELS according to xTrans and yTrans:
						//translate in situ signals for subsequent rounds
						
						// SPEED: Batch mode can increase the speed at which this occurs, BUT
						// you won't be able to watch the registration happen in real-time, meaning you
						// should be diligent in checking the registration for errors!
						
						// Be sure to turn off batch mode at the end of this (ctrl+F for SPEED)
						
						//setBatchMode(true);
						
						//new from kaitlin revisions 2025
						roundType = "R" + cnt + "_";
						chan = channels(dir, cnt);
						print(cnt);
						for (i = 0; i < chan.length; i++) {
							//open
							pref = chan[i];
							file = "R" + cnt + "_" + pref;
							print(file);
							autoOpen(dir, file);
							nm = getTitle();
							//translate
							translate(xTrans, yTrans);
							regImg = regDir + nm + "_registered.tif";
							saveAs("Tiff",regImg);
							close();
						}
						//run("Clear Results");
						
			//addition for autothreshold: include a file that holds the translation coords					
						tf = regDir + "translate" + cnt + ".txt";
						f = File.open(tf);
						print(f, xTrans + " \n" + yTrans);
						File.close(f);
						cnt++;
					}
					run("Close All");
					
					
			//SAVE R1:
			//new from kaitlin revisions 2025
					chan = channels(dir, 1);
				for (i = 0; i <= chan.length; i++) {
					if(i==0)
						pref = 405;
					else
						pref = chan[i-1];
	
					file = "R1_" + pref;
					autoOpen(dir, file);
					nm = getTitle();
				
					regImg = regDir + nm + "_registered.tif";
					saveAs("Tiff",regImg);
					close();
				}
				//close remaining windows
				run("Close All");
				
				// SPEED: If you chose to turn on batch mode, 
				// be sure to turn it off after
						
				// setBatchMode(false);

//STEP 4: NONLINEAR REGISTRATION:
	//(Rennie): Run bUnwarp
	//(Code augemented by kaitlin sullivan for brevity and less user checks

			//4A: SAVE RIGID REGISTRATION OVERLAY
				//merge rigid registration images
				dapiMerge(regDir, false);
				
				//save dapi overlay from linear reg
				compDir = regDir+"composite"+File.separator;
				File.makeDirectory(compDir);
				saveAs("Tiff", compDir + "rigid_composite.tif");	
				run("Close All");	

			//4B: CREATE FOLDERS
				//create new folder		
				nlDir = regDir + "nonLinearReg" + File.separator;
				File.makeDirectory(nlDir);

				//Copy R1 imgs to nonLinearReg file folder
				print("Copying Round 1 channels before proceeding with non-linear registration...");
				regFiles = getFileList(regDir);
				for (n=0; n < regFiles.length; n++){
					if (startsWith(regFiles[n],"R1")){
						File.copy(regDir+regFiles[n], nlDir+regFiles[n]+"_NL.tif");
					}
				}
			//4C: REGISTRATION LOOP
				// Register all subsequent rounds with round 1, saving the transformation from RX to R1 (for X=2,3...)
				print("Beginning non-linear registration...");
				//open R1 image
				autoOpen(regDir, "R1_405");
				target=getTitle();
				rnd = numRound(regDir);
				//new addition: keep the scale by saving original image scale
				selectWindow(target);
				getPixelSize(unit, pixelWidth, pixelHeight);
					
				for (m = 2; m <= rnd; m++) {
					//open DAPI from each round
					print("Opening DAPI image for Round" +m+ "...");
					source = "R" + m + "_405";
					autoOpen(regDir, source);
					curDAPI = getTitle();
					transf_file = nlDir+curDAPI+"_transf.txt";

					//run nonlinear registration
					print("Now registering R"+ m +" DAPI to R1 DAPI...");
					run("bUnwarpJ","source_image=&curDAPI target_image=&target registration=Mono image_subsample_factor=0 initial_deformation=[Very Coarse] final_deformation=[Super Fine] divergence_weight=0.1 curl_weight=0.1 landmark_weight=0 image_weight=1 consistency_weight=10 stop_threshold=0.01 save_transformations save_direct_transformation=["+transf_file+"]");
					selectWindow("Registered Source Image");
					run("Stack to Images");
					selectWindow("Registered Source Image");
					run("8-bit");

					//new addition 2022: reclaim lost scale prior to saving
					run("Set Scale...", "distance=1 known=pixelWidth unit=unit");
					saveAs("Tiff",nlDir + curDAPI +"_NL.tif");

					//Close all windows but target image (R1 DAPI)
					selectWindow(target);
					close("\\Others");
						
					print("Applying transformation to channel images...");
					
					
					// SPEED: Batch mode can increase the speed at which this occurs, BUT
					// you won't be able to watch the registration happen in real-time, meaning you
					// should be diligent in checking the registration for errors!
						
					// Be sure to turn off batch mode at the end of this (ctrl+F for SPEED)
					
					//setBatchMode(true);
						
						
					//open each channel
					//new from kaitlin revisions 2025
					roundType = "R" + m + "_";
					chan = channels(dir, m);
					for (k=0; k<chan.length; k++){			
						curChan = "R" + m + "_" + chan[k];
						autoOpen(regDir, curChan);
						channel_image = getTitle();

						//run dapi transform
						call("bunwarpj.bUnwarpJ_.elasticTransformImageMacro", regDir+target, regDir+channel_image,transf_file, nlDir+channel_image+"_NL.tif");
			   			selectWindow(target);
			   			//new addition 2022: reclaim lost scale
						run("Set Scale...", "distance=1 known=pixelWidth unit=unit");
						close("\\Others");
					}
				}
				run("Close All");
				
				// SPEED: Be sure to set batch mode as false after turning it on!
				// setBatchMode(false);
				
			//4D: SAVE COMPOSITES AND GIVE USER OUTPUT
				print("Creating final overlay of nonlinearly registered DAPIs.");
				dapiMerge(nlDir, true);

				if(!auto){
					Dialog.create("Elastic Registration Composite");
					Dialog.addMessage("The following composite shows the elastic registration of all DAPI images. \n \n (Note: this image can be found at regImages/composite)");
					Dialog.show();
				}
					
				//save image
				selectImage("Composite");
				saveAs("Tiff", compDir+"elastic_composite.tif");
				
			
				run("Close All");
				close("Results");
				if(!auto)
					exit("Registration Complete! \n \n To segment cell bodies, open first DAPI image from generated regImages folder and run Segmentation.");	
				else{
					print("Beginning segmentation...");
					autoOpen(nlDir, "R1_405_DAPI.tif");
					cmd = "Segmentation";
				} 			
			}

/////////////////////////////////////////////////////////////////////////////////////////////
//SEGMENTATION CODE				
				if (cmd == "Segmentation"){

	//STEP 1: SET UP
		//throw error if no images open
					if(nImages == 0){
						exit("No images open. \n Please open a DAPI image for segmentation.");
					}

					if(nImages > 1){
						exit("Please open only one DAPI image and close any other image windows.");
					}
		//set up important variables
					dir = getDirectory("image");
					nround = numRound(dir);
					name=getTitle;
					imgDir = dir + "analyzedImages" + File.separator;
					File.makeDirectory(imgDir);
					tabDir = dir + "analyzedTables" + File.separator;
					File.makeDirectory(tabDir);
					//new addition 2022: reclaim lost scale prior to saving
					getPixelSize(unit, pixelWidth, pixelHeight);
					

	//STEP 2: CHECK FOR SEGMENTATION MARKER (DAPI VS NISSL)
					//create GUI
					types = newArray("DAPI", "Nissl");
					
					Dialog.create("Segmentation Type");
					Dialog.addMessage("Segmentation Marker:");
					Dialog.addChoice("Segmentation Type: ", types);
					Dialog.show();

					//get value
					marker = Dialog.getChoice();

					//Run DAPI specific pre-processing
					if(marker == types[0]){
						run("Subtract Background...", "rolling=50");
						run("Gaussian Blur...", "sigma=2");
					}
					//Run Nissl specific pre-processing
					if(marker == types[1]){
						run("Smooth");
						run("Gaussian Blur...", "sigma=4");
						//ensure only the Nissl round is segmented
						seg = newArray(1);
						seg[0] = 1;
					}

	
					//if only one round, segment that alone
					if(nround<=1){
						seg = newArray(1);
						seg[0] = 1;
					}

		//STEP 3: SELECT ROUNDS TO SEGMENT
					if(nround>1){
						Dialog.create("Select Rounds to Segment");
						Dialog.addMessage("Select all DAPI rounds for z-stack registration, unless certain rounds have poor signal! \n (NOTE: Round 1 will ALWAYS be included)");
						
						//create and fill arrays to hold checkbox values
						labels = newArray(nround-1);
						defaults = newArray(nround-1);
						for (i = 0; i < nround-1; i++) {
							labels[i] = "Round " + (i+2);
							defaults[i] = true; 
						}
						
						//fill values into GUI
						Dialog.addCheckboxGroup(nround, 1, labels, defaults);
						Dialog.show();
						
						//get user input and save into a new array seg
						//array for rounds included
						seg = newArray(1);
						seg[0] = 1;
						
						//round counter
						rndCnt = 2;

						//iterate through user input and add to seg
						for (i = 1; i < nround; i++) {
							//check if round is included
							include = Dialog.getCheckbox();
							if(include){
								//add round number to the seg array
								curRound = newArray(1);
								curRound[0] = rndCnt;
								seg = Array.concat(seg, curRound);
							}
							//increase round after each iteration
							rndCnt++;
						}
						//print(seg.length);
					}
					
		//STEP 4: MANUALLY OR AUTOMATICALLY ADJUST THRESHOLD
					if(seg.length >= 1){
						//Create a new GUI
						Dialog.create("Thresholding Type");
						Dialog.addMessage("Would you like to automatically or manually threshold DAPI signals?");
						Dialog.addChoice("Thresholding Type: ", newArray("Automatic", "Manual"));
						Dialog.show();
						
						thr=Dialog.getChoice();
						
				//4A: MANUALLLY THRESHOLD
						if(thr=="Manual"){
							quant(name,dir,0,true,"MaxEntropy");
							run("Convert to Mask");
							name = getTitle();
							print("Thresholding "+name+"...");
						}
				//4B: AUTOTHRESHOLD		
						if(thr=="Automatic"){
							//old way = using histPercentile function
							setAutoThreshold("Huang dark");
							//setOption("BlackBackground", true);
							run("Convert to Mask");
							print("Thresholding "+name+"...");
						}


						//4Ai: ITERATE THROUGH INCLUDED ROUNDS if seg > 1
							for (i = 1; i < seg.length; i++) {
								//Open subsequent rounds
								pref = "R" + seg[i] + "_405_DAPI.tif";
								//print("pref="+pref);
								autoOpen(dir, pref);
			 					cur = getTitle();
			 					//print(cur);

			 					//Pre-process
			 					run("Subtract Background...", "rolling=50");
								run("Gaussian Blur...", "sigma=2");
							
								//threshold the image manually
								if(thr=="Manual"){
									quant(name,dir,0,true, "Huang dark");
									run("Convert to Mask");
									name = getTitle();
									print("Thresholding "+name+"...");
								}
								//threshold the image automatically
								if(thr=="Automatic"){
									setAutoThreshold("Huang dark");
									//setOption("BlackBackground", true);
									run("Convert to Mask");
									name = getTitle();
									print("Thresholding "+name+"...");
								}
							
								//multiply first two rounds
								if(i==1){
									run("Set Scale...", "distance=1 known=pixelWidth unit=unit");
									imageCalculator("Multiply create", name, cur);
									prod = getTitle();
									print(prod);
									close("\\Others");
								}
								//subsequent rounds
								if(i>=2){
									run("Set Scale...", "distance=1 known=pixelWidth unit=unit");
									imageCalculator("Multiply create", prod, cur);
									prod = getTitle();
									print(prod);
									close("\\Others");
								}
							//print(i);	
							}
						}
						//user selected no rounds
						else{
							exit("No rounds selected to segment.");
						}

					
					
			//5: ADD ROIS AND EXPAND
					//run watershed to separate clusters of nuclei
					run("Watershed", "stack"); // added Tim June 26 2019, helps with segmentation

					//select ROI for analysis
					waitForUser("Draw an ROI with polygon or rectangle tool, then hit OK here.");// added Tim, limit analysis to a specific ROI
					run("Add Selection...");
					run("To ROI Manager");
					run("Remove Overlay");

					//select ROIs between 30-250 microns
					run("From ROI Manager");
					roiManager("Select", 0);
					run("Analyze Particles...", "size=30-250 display clear add");

			//6: USER INPUT FOR DILATION VALUE
					Dialog.create("Dialate ROIs");
					Dialog.addSlider("Dialation: in microns", 0, 7, 3);
					Dialog.show();

					dilationVal = Dialog.getNumber();

			
					//Dilate ROIs by user-input
					run("Clear Results");
					totRois = roiManager("count");

					//Set measurements to be saved to results
					run("Set Measurements...", "area mean centroid perimeter fit shape feret's area_fraction redirect=None decimal=3");

					//Englarge ROIs
					if(dilationVal>0){
						for (mm=totRois-1;mm>-0.5;mm--){
							roiManager("Select",mm);
							run("Measure");
							run("Enlarge...","enlarge=dilationVal");
							roiManager("Update");	
						}
					}
					

					
			//6: UPDATE USER AND SAVE
					//print updates:
					print("Saving image stack, please wait...");
					
					roiManager("measure");
					print("Nuclei Segmented: " + totRois);
					//save ROISET for quant
					roiManager("Save", tabDir + "RoiSet.zip");
					//save results file
					resultsFile = tabDir + name +  "_segmented.csv";
					saveAs("Results",resultsFile);
					run("Clear Results");

					// Close down all unnecessary windows.
					// Note ROIs are left behind for use by other downstream macros
					run("Close All");
					close("Results");
					close("Threshold");
					close("ROI Manager");

					//Update user or continue to next
					if(!auto)
						exit("Segmentation Complete! \n To quantify, open the first in situ channel image and run Quantification.");
					else{
						print("Beginning quantification");
						autoOpen(dir, "R1_488");
						cmd = "Quantification";
					}
				}
/////////////////////////////////////////////////////////////////////////////////////////////
//QUANTIFICATION CODE			
				if (cmd == "Quantification" || cmd == "Single Channel Quantification") {

		//1: SETUP AND ERROR HANDLING
					//throw error if no images or more than one image open
					if(nImages == 0)
						exit("No images open.");
					if(nImages > 1)
						exit("Please open only one in situ image and close any other image windows. \n (Keep ROI Manager open)");
					
					//get directory and title of open image
					dir = getDirectory("image");
					name=getTitle;
					w = getWidth();
					h = getHeight();
					//check - kaitlin 2025
					totRnd = numRound(dir);
					//chk
					//print(totRnd);
					print(name);
					close("ROI Manager");

					//throw error if not a channel
					if (substring(name, 7, 11)=="DAPI") 
						exit("Probe channel image required.");

						
 					//create new file directories for the image masks and the quantification tables
					imgDir = dir + "analyzedImages" + File.separator;
					File.makeDirectory(imgDir);
					tabDir = dir + "analyzedTables" + File.separator;
					File.makeDirectory(tabDir);
					ovDir = dir + "overlay" + File.separator;
					File.makeDirectory(ovDir);
					corDir = dir + "correctedImages" + File.separator;
					File.makeDirectory(corDir); 
					//print(corDir);

					//only run when using Quantification
					if(!auto){
						//GUI for perfusions
						Dialog.create("Run background correction?");
						// Troubleshoot - Feel free to add more things here :)!
						Dialog.addChoice("Background Correction: ", newArray("yes", "no"), "yes");

						Dialog.show();

						bg = Dialog.getChoice();


					}
					
			//1B: OPEN ROIS	
					//open segmented ROIs
					close("ROI Manager");
					run("ROI Manager...");
					roi = tabDir + "RoiSet.zip";

					//open first image
					//s = substring(name, 0, 3);
					//pref = s + numChnl[0];
					//debug
					//print(s);
					//print(dir + pref);
					pref = name;
					autoOpen(dir, pref);
					//chk 2025
					//name=getTitle();
					
					//throw error if no ROIs saved
					if (!File.exists(roi)) 
						exit("Please run segmentation prior to quantification. \n If you wish to use external segmentation algorithms, place your RoiSet.zip file in analyzedTables");
					if(roiManager("count")==0)
						roiManager("Open", roi);
						print("start");
					
		//2A: SINGLE CHANNEL QUANTIFICATION - always manual
					if (cmd == "Single Channel Quantification") {
						// Clear results, in case populated from other analyses.
						run("Clear Results");
						
						//run("Subtract Background...", "rolling=50");
						
						//threshold
						quant(name, dir, 0, false, "MaxEntropy");
						saveFiles(name, ovDir, imgDir, tabDir, "quantification");
						run("Close All");
					}		
					
		//2B: FULL ROUND QUANTIFICATION
					else{
						//Save important variables:
						//directory
						dir = getDirectory("image");
						//counter 	
						ci = 1;
						cnt = 1;
						
						
						//total number of times to iterate
						//kaitlin 2025 - check
						tot = 0;
						for (t = 0; t <= totRnd; t++) {
							//chk
							numChnl = channels(dir, t);
							//Array.print(numChnl);
							print("channels in " + t + ":");
							Array.print(numChnl);
							len = numChnl.length;
							//chk
							//print("len: " + len);
							tot = tot + len;
							
							//chk
							//print("tot: "+ tot);
						}
						

		//3: SELECT METHOD OF QUANTIFICATION
						Dialog.create("Select Threshold Method...");
						Dialog.addMessage("Choose a method of thresholding: ");
						cc = newArray("Manual","Automatic");
						Dialog.addChoice("Method: ", cc, cc[1]);

						Dialog.show();
						opt = Dialog.getChoice();

				//3A: MULTIROUND QUANT		

					//Iterate through all channels
					rnd = 1;
					if(totRnd > 0){
						//auto-open all channels
						for (i = 1; i < tot; i++) {
							// Clear results, in case populated from other analyses.
							run("Clear Results");
							
				/////IMAGE CORRECTIONS
							//BG AVERAGING
							if(substring(name, 3, 6)==750){
								run("Smooth");
							}
							
							//Normal background subtraction
							if(bg=="yes"){
								run("Subtract Background...", "rolling=50");
							}
							
							//save with corrections
							stackFile = corDir + name;
							saveAs("Tiff",stackFile);
							
							
							//Auto cc[1] or Manual cc[0] Threshold
							if(opt==cc[1]){
								//perfused auto
								quant(name, dir, 1, false, "MaxEntropy");
								
							}
							else{
								//perfused manual
								quant(name, dir, 0, false, "MaxEntropy");
							}
							
							//Save files
							//chk
							//print("Check point #1 cleared");
							//print("save name: " + name);
							saveFiles(name, ovDir, imgDir, tabDir, "quantification");
							//chk
							//print("Final check point passed");
							//run("Close All");

							//increase the round when reached the end of the channel list
							print(rnd);
							cl = channels(dir, rnd);
							print("round "  + cnt);
							Array.print(cl);
							if(rnd==1){
								clen = cl.length - 1;
								print("cl = "+ clen);
							}
							if(rnd>1 && ci==1) {
								clen = cl.length;
								clen = cnt+(clen-1);
								print("cl = "+ clen);
							}
							if(i==clen){
								ci = 0;
								rnd++;
							}
							//open next image
							if(rnd <= totRnd){
								pref = "R" + rnd + "_" + cl[ci];
								//debugging 2025
								//chk
								//print("round "  + cnt);
								//print(pref+"next");
								//chk
								//Array.print(numChnl);
								autoOpen(dir, pref);
								name = getTitle();
								//print("next " + name);
								ci++;
								cnt++;
							}
						}
					}
		//3B: SINGLE ROUND QUANTIFICATION
					//if(totRnd == 1){
						//debug
						//Array.print(numChnl);
						
						//cnt = 0;
						//for (i = 0; i < numChnl.length; i++) {
							
							//auto vs manual thresholding
							//if(opt==cc[1]){
								//old way
								//quant(name, 1, false, "MaxEntropy");
							//}
							//else{
								//quant(name, 0, false, "MaxEntropy");
							//}
							//saveFiles(name, ovDir, imgDir, tabDir, "quantification");
							//run("Close All");
							//if(cnt+1<numChnl.length){
								//cnt++;
								//pref = "R1_" + numChnl[cnt];
								
								//debug
								//print(pref);
								
								//autoOpen(dir, pref);
								//name = getTitle();
							//}

		//4: FINISH THINGS UP
					run("Close All");
					close("Results");
					close("Threshold");
					}
					//Send user message
					if(!auto)
						exit("Quantification Complete \n For a final composite product: utilize HiPlex Overlay or Merge Channels for 3-Plex");
					else{
						print("Beginning overlay creation...");
						autoOpen(ovDir, "R1_488");
						cmd = "HiPlex Overlay";						
					}
				}

				
/////////////////////////////////////////////////////////////////////////////////////////////
//HIPLEX OVERLAY
				if (cmd == "HiPlex Overlay") {
					//set custom LUTS
					function myLuts(colour) { 
						choices = newArray("Green", "Magenta", "Cyan", "Yellow", "Red", "Blue", "Lavender", "Orange", "Purple", "PaleBlue", "Pink");
						for (i = 0; i < 6; i++) {
							if (colour == choices[i]) {
								run(choices[i]);
							}
						}
						dir = getDirectory("luts");
						for (i = 6; i < 11; i++) {
							if (colour == choices[i]){
								if (colour == choices[i]){
									path = dir + choices[i] + ".lut";
									open(path);
								}
							}
						}
					}
					
					dir = getDirectory("image"); //get filepath for directory of current image
					
					rnd = numRound(dir); //number of rounds

					//filepath for directory conaining quantified tables
					l = lengthOf(dir) - 8;
					 
					tabDir = substring(dir, 0, l) + "analyzedTables" + File.separator;
					//close first channel image
					close();
					//total number of times to iterate
						//kaitlin 2025 - check
						tot = 0;
						for (t = 0; t <= rnd; t++) {
							//chk
							numChnl = channels(dir, t);
							//Array.print(numChnl);
							//print("print " + numChnl);
							len = numChnl.length;
							//chk
							//print("len: " + len);
							tot = tot + len;
							
							//chk
							//print("tot: "+ tot);
						}
					
					fluo = newArray(tot); // array containing total ISH fluorescence
					names = newArray(tot); //array containing corresponding image names

					cnt = 0; //channel number
					//open each of the quantified tables and sum up total ISH signal
					for (i = 1; i <= rnd; i++) {
						//addition kaitlin 2025
						roundType = "R"+i+"_";
						chan = channels(dir, i); //get number of channels
						
						for(j = 0; j < chan.length; j++){
							
							sum = 0; //sum of fluorescence for each channel
							
							pref = chan[j];
							pref = "R" + (i) + "_" + pref;
							autoOpen(tabDir, pref);
							//check kaitlin 2025
							print(pref);

							//save image name
							names[cnt] = File.name;
							print(File.name);
							
							//resTab = tabDir + names[cnt];
							//run("Results... ", "open=" + resTab);

							//add up fluorescence
							for (x = 0; x < nResults; x++) {
								v = getResult("Mean", x);
								sum = sum + v;
							}
							
							fluo[cnt] = sum;

							close(names[cnt]);
							cnt++;
						}
					}
					close("Results");
					
					//Array.print(names);
					//Array.print(fluo);
					
					Array.sort(fluo, names);
					Array.reverse(fluo);
					Array.reverse(names);
					
					//Array.print(names);
					//Array.print(fluo);
					
///////////////////////////////////////////////////////////////////////////
//UNFINISHED GUI					
					//pop-up GUI for selecting colours
					
						//Dialog.create("HiPlex Overlay: Incomplete Macro");
						//Dialog.addMessage("This GUI does not work right now \n Changing any option here won't do anything (but will one day), so just press ok :)");
		//hard-coded colours
						colours = newArray("Select a Colour...", "White", "Green", "Magenta", "Cyan", "Yellow", "Red", "Lavender", "Blue", "Orange", "Purple", "PaleBlue", "Pink");

						//adds all options to pop-up window
						//for (i = 0; i < names.length; i++) {
							//Dialog.addCheckbox(" ", true);
							//Dialog.addToSameRow();
							////l = (lengthOf(names[i]) - 38);
							//Dialog.addString("Channel", (i+1));
							//Dialog.addToSameRow();
							//Dialog.addChoice(substring(names[i], 7, l), colours, colours[i+1]);
							////n = "Channel " + (i+1)+ ":";
							//Dialog.addChoice(n, names, names[i]);
							//Dialog.addToSameRow();
							//Dialog.addChoice(" ", colours, colours[i+1]);
						//}
						//Dialog.addCheckbox("Preview", false);

						//hide every image except for the overlay image
						setBatchMode(true);
						//open all images
						for (i = 0; i < names.length; i++) {
							//print(lengthOf(names[i]));
							//Array.print(names);
							ovName = dir + substring(names[i], 0, (lengthOf(names[i])-19));
							ovPath = dir + ovName;
							open(ovName);
						}
//display gui
						//Dialog.show();
///////////////////////////////////////////////////////////////////////////

					
//save inputted gene name and colour orders
						//newNames = newArray(names.length);
						//newColours = newArray(colours.length-1);
						//nCnt = 0;
						//cCnt = 0;
						//for (i = 0; i < (names.length*2); i++) {
							//if(((i+2)%2) == 0){
								//if(i == 0){
									//newNames[nCnt] = Dialog.getChoice();
									//nCnt++;
								//}
								//else{
									//newNames[nCnt] = Dialog.getChoice();
									//nCnt++;
								//}
							//}
							//else{
							//newColours[cCnt] = Dialog.getChoice();
							//cCnt++;
							//}	
						//}

					
					
					//checked preview
						//prev = Dialog.getCheckbox();
						//while(prev){
							//baseImg = dir + substring(newNames[0], 0, (lengthOf(names[0])-19));
							//selectWindow(baseImg);
							//base = getImageID();
						
						
						//change luts and overlay
							//for (i = 0; i < newNames.length; i++) {
								//ovName = substring(newNames[i], 0, (lengthOf(names[i])-19));
								//selectWindow(ovName);
								//myLuts(newColour[i]);
							//}
							//show only overlay image
							//setBatchMode("show");
							//for (i = 1; i < newNames.length; i++) {
								//overlay
								//selectImage(base);
								//run("Add Image...", "image="+ovName+" x=0 y=0 opacity=100 zero");

							//}
						//}
						setBatchMode(false);
///////////////////////////////////////////////////////////////					
					//open the base image and ensure greyscale
					//ovName = dir + substring(names[0], 0, (lengthOf(names[0])-19));
					ovName = dir + substring(names[0], 0, (lengthOf(names[0])-19));
					open(ovName);
					base = getImageID();
					run("Grays");

					print("Images are layered from highest to lowest expression based on quantification...");
					for (i = 1; i < names.length; i++) {
						//for all subsequent images: open and change lut
						ovName = substring(names[i], 0, (lengthOf(names[i])-19));
						ovPath = dir + ovName;
						open(ovPath);
						myLuts(colours[i]);
						print(i + ": " + colours[i] + " = " + names[i]);
						cur = getImageID();
						//overlay
						selectImage(base);
						run("Add Image...", "image="+ovName+" x=0 y=0 opacity=100 zero");
						selectImage(cur);
						close();	
					}
					path = dir + "TESTcomp";
					saveAs("PNG", path);
					if(auto){
						showMessage("Congratulations!!!", "Analysis complete ٩(^ᴗ^)۶");
					}
					//exit("This macro is still incomplete :)");			
				}

			}
					
		}
					
	}
	
}
