# SpyROSE spec computation
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
      }

ledNumberSensibility     = ["resolution", "radius"]
bladeNumberSensibility   = ["resolution", "height"]
radiusSensibility        = ["resolution", "LED_number_per_blade"]
heightSensibility        = ["resolution", "blade_number"]
resolutionSensibility    = ["LED_number_per_blade", "height", "radius",\
                            "blade_number"]
rotationSpeedSensibility = ["framerate"]
framerateSensibility     = ["rotation_speed"]
bandwidthSensibility     = ["LED_number_per_blade", "blade_number",\
                            "framerate", "bytes_per_LED"]
powerSensibility         = ["LED_number_per_blade", "blade_number",\
                            "voltage", "LED_power"]
tipSpeedSensibility      = ["rotation_speed", "radius"]

# Check if the specs required to compute a specific spec are defined
def checkSensibility(sensibilityList):
    for s in sensibilityList:
        if specs[s] == None:
            return False
    return True

def computeLedNumber():
    if not(checkSensibility(ledNumberSensibility)):
        return None
    specs["LED_number_per_blade"] = specs["radius"] // specs["resolution"][0]

def computeBladeNumber():
    if not(checkSensibility(bladeNumberSensibility)):
        return None
    specs["blade_number"] = specs["height"] // specs["resolution"][1]

def computeHeight():
    if not(checkSensibility(heightSensibility)):
        return None
    specs["height"] = specs["blade_number"] * specs["resolution"][1]

def computeRadius():
    if not(checkSensibility(radiusSensibility)):
        return None
    specs["radius"] = specs["LED_number_per_blade"] * specs["resolution"][0]

def computeResolution():
    if not(checkSensibility(resolutionSensibility)):
        return None
    specs["resolution"] = (specs["LED_number_per_blade"] // specs["radius"],\
                           specs["height"] // specs["blade_number"])

def computeFramerate():
    if not(checkSensibility(framerateSensibility)):
        return None
    specs["framerate"] = specs["rotation_speed"] // 60

def computeRotationSpeed():
    if not(checkSensibility(rotationSpeedSensibility)):
        return None
    specs["rotation_speed"] = specs["framerate"] * 60

def computeBandwidth():
    if not(checkSensibility(bandwidthSensibility)):
        return None
    specs["bandwidth"] = math.ceil(\
                         2 * math.pi * specs["radius"] / specs["resolution"][0]\
                         * 2 * specs["LED_number_per_blade"]\
                         * specs["blade_number"] * specs["bytes_per_LED"]\
                         * specs["framerate"] / (1024**2))

def computePower():
    if not(checkSensibility(powerSensibility)):
        return None
    specs["nominal_power"] = 2 * specs["blade_number"] * specs["LED_power"]\
                             * specs["LED_number_per_blade"] * specs["voltage"]\
                             + specs["engine_power"]

def computeTipSpeed():
    if not checkSensibility(tipSpeedSensibility):
        return None
    specs["tip_speed"] = specs["rotation_speed"] * 2*math.pi*specs["radius"] / 60



def fillSpec():
    if specs["LED_number_per_blade"] == None:
        computeLedNumber()
    if specs["blade_number"] == None:
        computeBladeNumber()
    if specs["height"] == None:
        computeHeight()
    if specs["radius"] == None:
        computeRadius()
    if specs["resolution"] == None:
        computeResolution()
    if specs["framerate"] == None:
        computeFramerate()
    if specs["rotation_speed"] == None:
        computeRotationSpeed()
    if specs["bandwidth"] == None:
        computeBandwidth()
    if specs["nominal_power"] == None:
        computePower()
    if specs["tip_speed"] == None:
        computeTipSpeed()

def printSpec():
    for s in specs:
        print(s + " : " + str(specs[s]))

def main():
    fillSpec()
    printSpec()

if __name__ == "__main__":
    main()
