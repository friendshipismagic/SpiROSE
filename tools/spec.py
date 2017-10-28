# SpiROSE spec computation
# Try to fill the dictionnary specs and then print it

import math

specs={"resolution"     : (0.00225, 0.00225), # m
      "framerate"       : 30   , # Hz
      "face_number"     : 2    , # 1 or 2
      "LED_per_face"    : None ,
      "LED_per_column"  : None ,
      "LED_per_row"     : None ,
      "radius"          : 0.2  , # m
      "height"          : 0.2  , # m
      "rotation_speed"  : None , # rpm
      "tip_speed"       : None , # m/s
      "bandwidth"       : None , # Mo/s
      "nominal_power"   : None , # Watt
      "bytes_per_LED"   : 2    ,
      "LED_power"       : 0.0465, # A
      "engine_power"    : 0    , # Watt
      "number_of_voxels": None ,
      }

LED_per_face_sensibility     = ["LED_per_row", "LED_per_column"]
LED_per_row_sensibility      = ["resolution", "radius"]
LED_per_column_sensibility   = ["resolution", "radius"]
radius_sensibility           = ["resolution", "LED_per_row"]
height_sensibility           = ["resolution", "LED_per_column"]
resolution_sensibility       = ["LED_per_row", "LED_per_column",\
                                "height", "radius"]
rotation_speed_sensibility   = ["framerate"]
framerate_sensibility        = ["rotation_speed"]
bandwidth_sensibility        = ["number_of_voxels", "framerate",\
                                "bytes_per_LED"]
power_sensibility            = ["LED_per_face", "LED_power", "engine_power"]
tip_speed_sensibility        = ["rotation_speed", "radius"]
number_of_voxels_sensibility = ["LED_per_row", "LED_per_column",\
                                "resolution", "face_number"]

# Check if the specs required to compute a specific spec are defined
def check_sensibility(sensibility_list):
    return all(specs[s] is not None for s in sensibility_list)

def compute_LED_per_row():
    if not check_sensibility(LED_per_row_sensibility):
        return None
    specs["LED_per_row"] = math.floor(specs["radius"] / specs["resolution"][0])

def compute_LED_per_column():
    if not check_sensibility(LED_per_column_sensibility):
        return None
    specs["LED_per_column"] = math.floor(specs["height"] / specs["resolution"][1])

def compute_LED_per_face():
    if not check_sensibility(LED_per_face_sensibility):
        return None
    specs["LED_per_face"] = specs["LED_per_row"] * specs["LED_per_column"]

def compute_height():
    if not check_sensibility(height_sensibility):
        return None
    specs["height"] = specs["LED_per_column"] * specs["resolution"][1]

def compute_radius():
    if not check_sensibility(radius_sensibility):
        return None
    specs["radius"] = specs["LED_per_row"] * specs["resolution"][0]

def compute_resolution():
    if not check_sensibility(resolution_sensibility):
        return None
    specs["resolution"] = (specs["radius"] / specs["LED_per_row"],\
                           specs["height"] / specs["LED_per_column"])

def compute_framerate():
    if not check_sensibility(framerate_sensibility):
        return None
    specs["framerate"] = specs["rotation_speed"] // 60

def compute_rotation_speed():
    if not check_sensibility(rotation_speed_sensibility):
        return None
    specs["rotation_speed"] = specs["framerate"] * 60

def compute_power():
    if not check_sensibility(power_sensibility):
        return None
    specs["nominal_power"] = 2 * specs["LED_per_face"]\
                               * specs["LED_power"]\
                               + specs["engine_power"]

def compute_tip_speed():
    if not check_sensibility(tip_speed_sensibility):
        return None
    specs["tip_speed"] = round(2 * math.pi * specs["radius"]\
                                 * specs["rotation_speed"] / 60, 2)

def compute_number_of_voxels():
    if not check_sensibility(number_of_voxels_sensibility):
        return None
    voxel_per_row = 0;
    ratio = specs["resolution"][0] / specs["resolution"][1]
    # The n-th LED on a semi-row is at distance n*resolution[0] from the center,
    # hence it produces 2*pi*n*resolution[0]/resolution[1] voxels
    for i in range(1, specs["LED_per_row"] // 2 + 1):
        voxel_per_row += math.ceil(2 * math.pi * i * ratio)
    specs["number_of_voxels"] = voxel_per_row * specs["LED_per_column"]\
                                * specs["face_number"]

def compute_bandwidth():
    if not check_sensibility(bandwidth_sensibility):
        return None
    specs["bandwidth"] = math.ceil(specs["number_of_voxels"]\
                         * specs["bytes_per_LED"]\
                         * specs["framerate"]\
                         / (1024*1024))

def fill_spec():
    if specs["LED_per_row"] is None:
        compute_LED_per_row()
    if specs["LED_per_column"] is None:
        compute_LED_per_column()
    if specs["LED_per_face"] is None:
        compute_LED_per_face()
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
    if specs["nominal_power"] is None:
        compute_power()
    if specs["tip_speed"] is None:
        compute_tip_speed()
    if specs["number_of_voxels"] is None:
        compute_number_of_voxels()
    if specs["bandwidth"] is None:
        compute_bandwidth()

def print_spec():
    for s in specs:
        print("{} : {}".format(s, specs[s]))

def main():
    fill_spec()
    print_spec()

if __name__ == "__main__":
    main()
