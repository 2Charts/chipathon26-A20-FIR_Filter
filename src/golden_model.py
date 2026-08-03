import numpy as np

def get_hardware_accurate_output(samples, coeffs, mode):
    """
    mode: 0=Asym, 4=SymEven, 5=SymOdd, 6=AntiEven, 7=AntiOdd
    """
    # 0xx -> Asymmetric
    # 100 -> Symmetric, Even
    # 101 -> Symmetric, Odd
    # 110 -> Anti-symmetric, Even
    # 111 -> Anti-symmetric, Odd
    
    is_asym = (mode & 0b100) == 0
    is_odd = (mode & 0b001) == 1
    is_anti = (mode & 0b010) == 2
    
    out = []
    
    # Internal state mimicking hardware registers
    sipo_top = [0] * 16  # [x[t], x[t-1], ..., x[t-15]]
    sipo_bot = [0] * 16  # [x[t-16] ... x[t-31]]
    
    for t in range(len(samples)):
        sample_i = samples[t]
        
        # Shift registers (simulating clock edge)
        # Shift bottom
        for i in range(15, 0, -1):
            sipo_bot[i] = sipo_bot[i-1]
        sipo_bot[0] = sipo_top[15]
            
        # Shift top
        for i in range(15, 0, -1):
            sipo_top[i] = sipo_top[i-1]
        sipo_top[0] = sample_i
        
        # Accumulate
        acc = 0
        for cnt in range(16):
            c = coeffs[cnt]
            sel_i = 15 - cnt
            
            # Top mux
            mux_top = sipo_top[cnt] 
            
            # Bot mux and routing
            if is_asym:
                mux_bot_routed = 0
            elif is_odd:
                if sel_i == 0:
                    mux_bot_routed = 0
                else:
                    mux_bot_routed = sipo_bot[sel_i - 1]
            else:
                mux_bot_routed = sipo_bot[sel_i]
                
            # Pre-adder
            if is_anti:
                bot_ext = -mux_bot_routed
            else:
                bot_ext = mux_bot_routed
                
            pre_adder = mux_top + bot_ext
            
            # MAC
            acc += c * pre_adder
            
        # Rounding and saturation
        y = (acc + 0x4000) >> 15
        
        # Clip to 16-bit signed
        y = max(-32768, min(32767, y))
        out.append(y)
        
    return out

def get_floating_point_output(samples, coeffs, mode):
    is_asym = (mode & 0b100) == 0
    is_odd = (mode & 0b001) == 1
    is_anti = (mode & 0b010) == 2
    
    if is_asym:
        h = np.array(coeffs, dtype=float)
    else:
        num_taps = 31 if is_odd else 32
        h = np.zeros(num_taps, dtype=float)
        for i in range(16):
            h[i] = coeffs[i]
            mirrored_idx = (num_taps - 1) - i
            if mirrored_idx < num_taps and mirrored_idx >= 0:
                if mirrored_idx == i:
                    h[mirrored_idx] = coeffs[i]
                else:
                    h[mirrored_idx] = -coeffs[i] if is_anti else coeffs[i]
                
    # Direct float convolution
    samples_float = np.array(samples, dtype=float)
    
    # Mathematically: y = sum(x * c) / 32768.0
    y_float = np.convolve(samples_float, h) / 32768.0
    
    # Hardware rounding behavior matches floor(val + 0.5)
    y_int = np.floor(y_float + 0.5).astype(int)
    
    # Saturation
    y_int = np.clip(y_int, -32768, 32767).tolist()
    
    # We only care about the outputs corresponding to the input samples fed in sequence
    return y_int[:len(samples)]

if __name__ == "__main__":
    coeffs = [(i+1)*100 for i in range(16)]
    samples = [1000, -2000, 3000, -4000, 5000]
    
    for mode_name, mode_val in [("Asym", 0), ("Sym Even", 4), ("Sym Odd", 5), ("Anti Even", 6), ("Anti Odd", 7)]:
        hw_out = get_hardware_accurate_output(samples, coeffs, mode_val)
        fl_out = get_floating_point_output(samples, coeffs, mode_val)
        
        print(f"{mode_name}:")
        print(f"  HW: {hw_out}")
        print(f"  FL: {fl_out}")
