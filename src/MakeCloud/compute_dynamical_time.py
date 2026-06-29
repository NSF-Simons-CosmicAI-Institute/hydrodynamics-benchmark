import sys
import math
import numpy as np

M_gas = float(sys.argv[1])
R = float(sys.argv[2])
G = 4300.71
rho_avg = 3 * M_gas / R**3 / (4 * np.pi)
tff = (3 * np.pi / (32 * G * rho_avg)) ** 0.5

print(tff)
