import numpy as np

def get_expected_output(samples, coeffs, mode):
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
    sipo_mid = 0         # x[t-16]
    sipo_bot = [0] * 15  # x[t-16...t-30] if even, x[t-17...t-31] if odd
    
    for t in range(len(samples)):
        sample_i = samples[t]
        
        # Shift registers (simulating clock edge)
        # Shift bottom
        for i in range(14, 0, -1):
            sipo_bot[i] = sipo_bot[i-1]
        
        if is_odd:
            sipo_bot[0] = sipo_mid
        else:
            sipo_bot[0] = sipo_top[15]
            
        # Shift mid
        sipo_mid = sipo_top[15]
        
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
            mux_top = sipo_top[cnt] # which is sipo_top[16 - (15-cnt) - 1]
            
            # Bot mux
            if sel_i == 15:
                mux_bot = sample_i
            else:
                # sel_i goes from 14 down to 0, which maps to sipo_bot index 0 to 14
                mux_bot = sipo_bot[cnt - 1] 
                
            # Routing
            if is_asym:
                mux_bot_routed = 0
            elif is_odd and sel_i == 15:
                mux_bot_routed = 0
            else:
                mux_bot_routed = mux_bot
                
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

if __name__ == "__main__":
    coeffs = [(i+1)*100 for i in range(16)]
    samples = [1000, -2000, 3000, -4000, 5000]
    
    # Asymmetric
    print(f"Asym:       {get_expected_output(samples, coeffs, 0)}")
    # Symmetric Even
    print(f"Sym Even:   {get_expected_output(samples, coeffs, 4)}")
    # Symmetric Odd
    print(f"Sym Odd:    {get_expected_output(samples, coeffs, 5)}")
    # Anti-Sym Even
    print(f"Anti Even:  {get_expected_output(samples, coeffs, 6)}")
    # Anti-Sym Odd
    print(f"Anti Odd:   {get_expected_output(samples, coeffs, 7)}")
