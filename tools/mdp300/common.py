import numpy as np, cv2, glob
from PIL import Image
def layer_ink(path):  # ink alpha-weighted darkness 0..255
    a = np.array(Image.open(path).convert('RGBA')).astype(np.float32)
    g = a[...,:3].mean(-1); al = a[...,3]/255
    return np.clip((255-g)*al,0,255).astype(np.uint8)
def match(src, dst, nfeat=0):
    ak = cv2.SIFT_create(nfeatures=4000)
    k1,d1 = ak.detectAndCompute(src,None); k2,d2 = ak.detectAndCompute(dst,None)
    if d1 is None or d2 is None or len(k1)<4 or len(k2)<4: return None,0
    bf = cv2.BFMatcher(cv2.NORM_L2)
    ms = bf.knnMatch(d1,d2,k=2)
    good=[m[0] for m in ms if len(m)==2 and m[0].distance<0.8*m[1].distance]
    if len(good)<6: return None,len(good)
    p1=np.float32([k1[m.queryIdx].pt for m in good]); p2=np.float32([k2[m.trainIdx].pt for m in good])
    M,inl=cv2.estimateAffinePartial2D(p1,p2,method=cv2.RANSAC,ransacReprojThreshold=4,maxIters=5000)
    return M,int(inl.sum()) if inl is not None else 0
