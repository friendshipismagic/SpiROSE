# SpiROSE spec computation
# Try to fill the dictionnary specs and then print it

import math

specs={"resolution"     : (0.00225, 0.00225), # m
      "framerate"       : 30  , # Hz
      "horizontal_staggering":True,
      "vertical_staggering":False,
      "face_number"     : 2    , # 1 or 2
      "LED_per_face"    : None ,
      "LED_per_column"  : 48 ,
      "LED_per_row"     : 40 ,
      "width"           : 0.187  , # m
      "height"          : 0.105  , # m
      "rotation_speed"  : None , # rpm
      "tip_speed"       : None , # m/s
      "bandwidth"       : None , # Mo/s
      "nominal_power"   : None , # Watt
      "bytes_per_LED"   : 2    ,
      "LED_power"       : 0.0465, # Watt
      "engine_power"    : 0   , # Watt
      "number_of_voxels":None ,
      "number_of_driver":None ,
      "driver_bandwidth":None , # MHz
      "multiplexing"    :8    ,
      "driver_bit_per_LED":27 ,
      "driver_channels":16,
      "slice_number":256,
      "fpga_memory":1161216, # bit
      }

LED_per_face_sensibility     = ["LED_per_row", "LED_per_column"]
LED_per_row_sensibility      = ["resolution", "width"]
LED_per_column_sensibility   = ["resolution", "width"]
width_sensibility           = ["resolution", "LED_per_row"]
height_sensibility           = ["resolution", "LED_per_column"]
resolution_sensibility       = ["LED_per_row", "LED_per_column",\
                                "height", "width"]
rotation_speed_sensibility   = ["framerate"]
framerate_sensibility        = ["rotation_speed"]
bandwidth_sensibility        = ["number_of_voxels", "framerate",\
                                "bytes_per_LED"]
power_sensibility            = ["LED_per_face", "LED_power", "engine_power"]
tip_speed_sensibility        = ["rotation_speed", "width"]
number_of_voxels_sensibility = ["LED_per_face", "width", "resolution"]
number_of_driver_sensibility = ["LED_per_face", "multiplexing",\
                                "driver_channels"]
driver_bandwidth_sensibility = ["width", "multiplexing",\
                                "driver_channels", "driver_bit_per_LED",\
                                "framerate", "resolution"]

# Check if the specs required to compute a specific spec are defined
def check_sensibility(sensibility_list):
    return all(specs[s] is not None for s in sensibility_list)

def compute_LED_per_row():
    if not check_sensibility(LED_per_row_sensibility):
        return None
    specs["LED_per_row"] = math.floor(specs["width"] / specs["resolution"][0]\
                           / (2 if specs["horizontal_staggering"] else 1))

def compute_LED_per_column():
    if not check_sensibility(LED_per_column_sensibility):
        return None
    specs["LED_per_column"] = math.floor(specs["height"]\
                              / specs["resolution"][1]\
                              / (2 if specs["vertical_staggering"] else 1))

def compute_LED_per_face():
    if not check_sensibility(LED_per_face_sensibility):
        return None
    specs["LED_per_face"] = specs["LED_per_row"] * specs["LED_per_column"]

def compute_height():
    if not check_sensibility(height_sensibility):
        return None
    specs["height"] = specs["LED_per_column"] * specs["resolution"][1]\
                      * (2 if specs["vertical_staggering"] else 1)

def compute_width():
    if not check_sensibility(width_sensibility):
        return None
    specs["width"] = specs["LED_per_row"] * specs["resolution"][0]\
                     * (2 if specs["horizontal_staggering"] else 1)

def compute_resolution():
    if not check_sensibility(resolution_sensibility):
        return None
    specs["resolution"] = (specs["width"] / specs["LED_per_row"]\
                           / (2 if specs["horizontal_staggering"] else 1),\
                           specs["height"] / specs["LED_per_column"]\
                           / (2 if specs["vertical_staggering"] else 1))

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
    specs["tip_speed"] = round(2 * math.pi * specs["width"] / 2\
                                 * specs["rotation_speed"] / 60, 2)

def compute_number_of_voxels():
    if not check_sensibility(number_of_voxels_sensibility):
        return None
    refresh_number = math.ceil(math.pi*specs["width"] / specs["resolution"][0])
    specs["number_of_voxels"] = refresh_number * specs["LED_per_face"]

def compute_bandwidth():
    if not check_sensibility(bandwidth_sensibility):
        return None
    specs["bandwidth"] = math.ceil(specs["number_of_voxels"]\
                         * specs["face_number"]\
                         * specs["bytes_per_LED"]\
                         * specs["framerate"]\
                         / (1024*1024))

def compute_number_of_driver():
    if not check_sensibility(number_of_driver_sensibility):
        return None
    led_per_driver = specs["multiplexing"] * specs["driver_channels"]
    specs["number_of_driver"] = specs["face_number"]\
                                * specs["LED_per_face"] / led_per_driver

def compute_driver_bandwidth():
    if not check_sensibility(driver_bandwidth_sensibility):
        return None
    led_per_driver = specs["multiplexing"] * specs["driver_channels"]
    refresh_number = math.ceil(math.pi*specs["width"] / specs["resolution"][0])
    specs["driver_bandwidth"] = led_per_driver * refresh_number\
                                * specs["framerate"]\
                                * specs["driver_bit_per_LED"]\
                                / (1000*1000)

def fpga_requirement():
    ''' We check the following constraints (see wiki for details):
        * m < n, m = 2^r
        * (v2 + dv)t + 2*m - n < v2*t < (v2 + dv)t + m
        Here v2 and dv are in slice/s, and a slice is nb_led*nb_bit_rgb bit
    '''
    dv_max = []
    v2 = specs["rotation_speed"] / 60 * specs["slice_number"]
    slice_size = specs["face_number"] * specs["LED_per_face"]\
                 * specs["bytes_per_LED"]*8
    n = specs["fpga_memory"] // slice_size
    m = 1
    while m < n:
        # dv is the delta v between the reading and the writing
        dv = 0
        # t is when we have read a whole semi-turn
        t = 128 / v2
        within_requirement = True
        while within_requirement:
            dv += 1
            # check that we don't write before we read
            within_requirement &= (v2 + dv)*t + 2*m - n < v2*t
            # check thta we don't read before we write
            within_requirement &=  v2*t < (v2 + dv)*t + m
        dv_max.append((int(dv*100/v2), n, m))
        m *= 2
    print("FPGA delta v max within requirement:" + str(dv_max))

def fill_spec():
    if specs["LED_per_row"] is None:
        compute_LED_per_row()
    if specs["LED_per_column"] is None:
        compute_LED_per_column()
    if specs["LED_per_face"] is None:
        compute_LED_per_face()
    if specs["height"] is None:
        compute_height()
    if specs["width"] is None:
        compute_width()
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
    if specs["number_of_driver"] is None:
        compute_number_of_driver()
    if specs["driver_bandwidth"] is None:
        compute_driver_bandwidth()

def print_spec():
    for s in specs:
        print("{} : {}".format(s, specs[s]))

def main():
    fill_spec()
    print_spec()
    fpga_requirement()

if __name__ == "__main__":
    main()
