import sys

def check_def(def_file):
    # DBU is 1000 in GF180 OpenROAD DEF
    # We want to check x: 0 to 5000 (5um), y: 0 to 25000 (25um)
    in_special_nets = False
    in_nets = False
    metal2_shapes = []
    
    with open(def_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('SPECIALNETS'):
                in_special_nets = True
            elif line.startswith('END SPECIALNETS'):
                in_special_nets = False
            elif line.startswith('NETS'):
                in_nets = True
            elif line.startswith('END NETS'):
                in_nets = False
                
            if in_special_nets or in_nets:
                if 'Metal2' in line:
                    # Very rough check, just grab lines with Metal2 and coordinates
                    pass

    # A better way is to use klayout to query shapes
print("Script ready")
