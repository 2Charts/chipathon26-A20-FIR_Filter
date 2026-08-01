import numpy as np

def get_expected_output(samples, coeffs):
    full_c = coeffs[::-1] + [-x for x in coeffs]
    y = np.convolve(samples, full_c)
    y = (y + 0x4000) >> 15
    return np.clip(y, -32768, 32767).tolist()

if __name__ == "__main__":
    coeffs = [(i+1)*100 for i in range(16)]
    samples = [1000, -2000, 3000, -4000, 5000]
    
    out = get_expected_output(samples, coeffs)
    print(f"Output: {out}")
