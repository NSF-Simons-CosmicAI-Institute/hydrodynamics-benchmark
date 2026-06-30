import sys
import math
import numpy as np

years = float(sys.argv[1])
#code_units = years*(3600*24*365.25)*((149597870700)/(math.tan(np.pi/648000)))**(-1) #exact
code_units = years*(3600*24*365.25)*1/(3.09e16)

print(code_units)
