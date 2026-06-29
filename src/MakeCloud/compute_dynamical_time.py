import sys
import math
import numpy as np

M_gas = float(sys.argv[1])
R = float(sys.argv[2])
alpha_turb = float(sys.argv[3])

turbulence = alpha_turb/2
G = 4300.71
L = (4 * np.pi * R**3 / 3) ** (1.0 / 3)  # volume-equivalent box size
vrms = (6 / 5 * G * M_gas / R) ** 0.5 * turbulence**0.5
tcross = L/vrms
print(tcross)
