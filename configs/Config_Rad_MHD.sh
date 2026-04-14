SINGLE_STAR_STARFORGE_DEFAULTS
MAGNETIC
COOLING
USE_FFTW3
# SINGLE_STAR_FB_JETS

# Radiation Bands
RT_LYMAN_WERNER                        # specific lyman-werner [narrow H2 dissociating] band 11.2 to 13.6 eV, 
RT_PHOTOELECTRIC                       # far-uv (8-13.6eV): track photo-electric heating photons + their dust interactions
RT_NUV                                 # near-UV: 1550-3600 Angstrom (where direct stellar emission dominates) 8.00 to 3.44 eV
RT_OPTICAL_NIR                         # optical+near-ir: 3600 Angstrom-3 micron (where direct stellar emission dominates) 3.44eV to 0.41 eV
RT_ISRF_BACKGROUND

SINGLE_STAR_FB_RAD
# SINGLE_STAR_FB_WINDS
# SINGLE_STAR_FB_SNE
BOX_PERIODIC
#GRAVITY_NOT_PERIODIC
#NO_GRAVITY
SELFGRAVITY_OFF
#EOS_ENFORCE_ADIABAT=4e4
ADAPTIVE_TREEFORCE_UPDATE=0.0625
OPENMP=2
STARFORGE_GMC_TURBINIT=1
TURB_DRIVING
