import sys
import math
import numpy as np

years = float(sys.argv[1])
code_units = years*(3600*24*365.25)*((149597870700)/(math.tan(np.pi/648000)))**(-1)

print(code_units)