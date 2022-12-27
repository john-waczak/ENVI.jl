import numpy as np
import spectral.io.envi as envi



A = np.random.rand(10,10,10)


envi.save_image("./test.bil.hdr", A, ext="", interleave="bil")
envi.save_image("./test.bip.hdr", A, ext="", interleave="bip")
envi.save_image("./test.bsq.hdr", A, ext="", interleave="bsq")
