# SpiROSE spec computation
# Try to fill the dictionnary specs and then print it

import math

specs={"framerate":40           , # Hz
      "LED_number_per_blade":32 ,
      "resolution":(0.005, 0.01), # m
      "radius":0.25             , # m
      "height":0.1              , # m
      "blade_number":10         ,
      "rotation_speed":None     , # rpm
      "tip_speed": None         , # m/s
      "bandwidth":None          , # Mo/s
      "nominal_power":None      , # Watt
      "bytes_per_LED":2         ,
      "LED_power":0.010         , # A
      "voltage":3.3             , # V
      "engine_power":0          , # Watt
      "matrix_number_of_voxels": None,
      "matrix_bandwidth": None,   # Mo/s
      }

LED_number_sensibility     = ["resolution", "radius"]
blade_number_sensibility   = ["resolution", "height"]
radius_sensibility         = ["resolution", "LED_number_per_blade"]
height_sensibility         = ["resolution", "blade_number"]
resolution_sensibility     = ["LED_number_per_blade", "height", "radius",\
                              "blade_number"]
rotation_speed_sensibility = ["framerate"]
framerate_sensibility      = ["rotation_speed"]
bandwidth_sensibility      = ["LED_number_per_blade", "blade_number",\
                              "framerate", "bytes_per_LED"]
power_sensibility          = ["LED_number_per_blade", "blade_number",\
                              "voltage", "LED_power"]
tip_speed_sensibility      = ["rotation_speed", "radius"]
matrix_number_of_voxels_sensibility = ["LED_number_per_blade", "blade_number"]
matrix_bandwidth_sensibility        = ["matrix_number_of_voxels", "framerate",\
                                       "bytes_per_LED"]


# Check if the specs required to compute_ a specific spec are defined
def check_sensibility(sensibility_list):
    return all(specs[s] is not None for s in sensibility_list)

def compute_LED_number():
    if not check_sensibility(LED_number_sensibility):
        return None
    specs["LED_number_per_blade"] = specs["radius"] // specs["resolution"][0]

def compute_blade_number():
    if not check_sensibility(blade_number_sensibility):
        return None
    specs["blade_number"] = specs["height"] // specs["resolution"][1]

def compute_height():
    if not check_sensibility(height_sensibility):
        return None
    specs["height"] = specs["blade_number"] * specs["resolution"][1]

def compute_radius():
    if not check_sensibility(radius_sensibility):
        return None
    specs["radius"] = specs["LED_number_per_blade"] * specs["resolution"][0]

def compute_resolution():
    if not check_sensibility(resolution_sensibility):
        return None
    specs["resolution"] = (specs["LED_number_per_blade"] // specs["radius"],\
                           specs["height"] // specs["blade_number"])

def compute_framerate():
    if not check_sensibility(framerate_sensibility):
        return None
    specs["framerate"] = specs["rotation_speed"] // 60

def compute_rotation_speed():
    if not check_sensibility(rotation_speed_sensibility):
        return None
    specs["rotation_speed"] = specs["framerate"] * 60

def compute_bandwidth():
    if not check_sensibility(bandwidth_sensibility):
        return None
    specs["bandwidth"] = math.ceil(\
                         2 * math.pi * specs["radius"] / specs["resolution"][0]\
                         * 2 * specs["LED_number_per_blade"]\
                         * specs["blade_number"] * specs["bytes_per_LED"]\
                         * specs["framerate"] / (1024**2))

def compute_power():
    if not check_sensibility(power_sensibility):
        return None
    specs["nominal_power"] = 2 * specs["blade_number"] * specs["LED_power"]\
                             * specs["LED_number_per_blade"] * specs["voltage"]\
                             + specs["engine_power"]

def compute_tip_speed():
    if not check_sensibility(tip_speed_sensibility):
        return None
    specs["tip_speed"] = specs["rotation_speed"] * 2*math.pi*specs["radius"] / 60

def compute_matrix_number_of_voxels():
    if not check_sensibility(matrix_number_of_voxels_sensibility):
        return None
    specs["matrix_number_of_voxels"] = specs["LED_number_per_blade"]**2 * specs["blade_number"]

def compute_matrix_bandwidth():
    if not check_sensibility(matrix_bandwidth_sensibility):
        return None
    specs["matrix_bandwidth"] = specs["matrix_number_of_voxels"] \
            * specs["bytes_per_LED"] \
            * specs["framerate"] \
            / (1024*1024)



def fill_spec():
    if specs["LED_number_per_blade"] is None:
        compute_LED_number()
    if specs["blade_number"] is None:
        compute_blade_number()
    if specs["height"] is None:
        compute_height()
    if specs["radius"] is None:
        compute_radius()
    if specs["resolution"] is None:
        compute_resolution()
    if specs["framerate"] is None:
        compute_framerate()
    if specs["rotation_speed"] is None:
        compute_rotation_speed()
    if specs["bandwidth"] is None:
        compute_bandwidth()
    if specs["nominal_power"] is None:
        compute_power()
    if specs["tip_speed"] is None:
        compute_tip_speed()
    if specs["matrix_number_of_voxels"] is None:
        compute_matrix_number_of_voxels()
    if specs["matrix_bandwidth"] is None:
        compute_matrix_bandwidth()

def print_spec():
    for s in specs:
        print("{} : {}".format(s, specs[s]))

def main():
    fill_spec()
    print_spec()

if __name__ == "__main__":
    main()
