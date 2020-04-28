# ESM-R-script
Script created for ESM calculations on large datasets

# Supplemental Script for
> Von Haden, A.C., Yang, W.H., DeLucia, E.H. April 20, 2020. [“Soils’ Dirty Little Secret: Depth‐Based Comparisons can be Inadequate for Quantifying Changes in Soil Organic Carbon and Other Mineral Soil Properties.”](https://onlinelibrary.wiley.com/doi/abs/10.1111/gcb.15124) Global Change Biology. DOI: 10.1111/gcb.15124.

# Overview
This script is intended to provide a starting point for users to implement the equivalent soil mass
(ESM) approach for calculating soil organic carbon (SOC) stocks and SOC mass percentages
(commonly called “SOC concentration”). The user should read this guide and understand how
the script works before using it. The script contains some basic error checking algorithms, but it
cannot catch all data entry mistakes. It is possible to misuse the script and produce invalid
results. The script was designed to work on individual soil cores that have been divided into
three or more contiguous segments, as the cubic spline function contains four coefficients. The
script has not been tested on soil cores containing fewer than three contiguous segments. If only
one segment is present, interpolation will necessarily be linear rather than cubic, which is
expected to result in higher predictive error (Wendt & Hauser, 2013). Considering the wide
range of potential applications, the script should not be expected to function correctly in all
situations. The user is encouraged to modify or rewrite the script to meet their specific needs.

# Prerequisites
R packages:
* openxlsx (Schauberger & Walker, 2019)
* dplyr (Wickham et al., 2019)
* tidyr (Wickham & Henry, 2019) 

# Input
An XLSX file must be used as input for the script. See the example file Example_datasets.xlsx. The format of the script is as below.

* ID: A name to identify a unique collection of samples. For example, this might include a combination of year, treatment, plot, and station. 
* Rep: A name that can be used if multiple collections of samples (unique instances of ID + Rep) will be compared against a single Ref_ID. If this field is not needed, it can be set to a common value (e.g., 1). 
* Ref_ID: A name to identify the sample or collection of samples from which the reference masses will be calculated. Each unique combination of “ID” and “Rep” should contain the same “Ref_ID.” 
* Upper_cm: The upper depth (i.e., closest to the soil surface) for the sample (cm). This must be a number. Each collection of samples (i.e., ID + Rep) must contain a sample with 0 cm as the upper depth.
* Lower_cm: The lower depth (i.e., furthest from the soil surface) for the sample. This must be a number. The lower depth must be equal to the upper depth of the adjacent sample within any collection of samples (i.e., ID + Rep). For example, if the lower depth is 10 cm for the first segment in a collection of samples, then the upper depth for the next segment must be 10 cm. Indeed, the primary purpose of the “Upper_cm” and “Lower_cm” is to provide a way to verify that collections of samples contain contiguous, adjacent depth increments, as cumulative values cannot be properly calculated from non-contiguous samples. The “Upper_cm” and “Lower_cm” values are also used to convert from apparent soil bulk density values to soil mass per unit area.
* SOC_pct: The mass percent of soil organic carbon (SOC) in the soil sample (g SOC 100 g soil-1). This is the format commonly given by elemental analyzers.
* SOM_pct: The mass percent of soil organic matter (SOM) in the sample (g SOM 100 g soil-1). If SOM was not measured (e.g., by loss on ignition), then the user may estimate SOM mass percent from SOC mass percent using a conversion factor (e.g., McBratney & Minasny, 2010). The SOM mass percent is needed to calculate mineral soil mass, and therefore a value is required to be supplied by the user.
* BD_g_cm3: The apparent soil bulk density (g dry soil cm-3). This is calculated based on the weight of dry fine earth (i.e., < 2 mm), which hence removes rocks and other coarse material from the mass. The apparent soil bulk density is calculated from the same sample in which SOC_pct and SOM_pct are measured.

# Usage
1. In the "User input" section of the script, change the "input_file_name" variable to the path and filename of the input XLSX file, and the “input_file_sheet” to the name of the sheet in the input XLSX file with the information. 
2. Change the “output_filename” variable to the desired output name for the output XLSX.
3. Provide a minimum length (cm) of a collection of samples(e.g., cores) that will be kept in the dataset for the “min_core_length_cm” variable.
4. The "extrapolation" variable must be set to TRUE (allow extrapolation outside the sample mass) or FALSE (do not allow extrapolation outside the sample mass).
5. Last, the “ESM_depths_cm” vector must contain the depths (cm) in the reference samples at which the equivalent soil masses are calculated. All depth provided in this vector must be present in the collection reference samples.

# Output
The output spreadsheet has two sheets: one for fixed depth and the other for equivalent soil mass. The Ref_ID contains blank values in the FD sheet because reference samples are ot used in FD calculations. All soil properties are given in the ESM sheet are ESM-based.
* Soil_g_cm2: Total sample soil mass (g soil cm-2)
* SOC_g_cm2: SOC mass within the sample (g SOC cm-2)
* SOM_g_cm2: SOM mass within the sample (g SOM cm-2)
* Min_Soil_g_cm2: Mineral soil mass within the sample (g mineral soil cm-2)
* Cum_Soil_g_cm2: The cumulative soil within each group of samples (g soil cm-2)
* Cum_SOC_g_cm2: The cumulative SOC mass within each group of samples (g SOC cm-2)
* Cum_SOM_g_cm2: The cumulative SOM mass within each group of samples (g SOM cm-2)
* Cum_Min_Soil_g_cm2: The cumulative mineral soil mass within each group of samples (g mineral soil cm-2)

# Citation 
> Von Haden, A.C., Yang, W.H., DeLucia, E.H. April 20, 2020. “Soils’ Dirty Little Secret: Depth‐Based Comparisons can be Inadequate for Quantifying Changes in Soil Organic Carbon and Other Mineral Soil Properties.” Global Change Biology. DOI: 10.1111/gcb.15124.

# References

McBratney, A. B., Minasny, B. (2010). Comment on "Determining soil carbon stock changes: Simple bulk density corrections fail". Agriculture, Ecosystems & Environment, 136, 185–186. doi: 10.1016/j.agee.2009.12.010

Schauberger, S., Walker, A. (2019). openxlsx: Read, write and edit XLSX files. R package version 4.1.4.

Wendt, J. W., Hauser, S. (2013). An equivalent soil mass procedure for monitoring soil organic carbon in multiple soil layers. European Journal of Soil Science, 64, 58–65. doi:10.2136/sssaj2008.0063

Wickham, H., François, R., Henry, L., Müller, K. (2019). dplyr: A grammar of data manipulation. R package version 0.8.3.

Wickham, H., Henry, L. (2019). tidyr: Tidy Messy Data. R package version 1.0.0.
