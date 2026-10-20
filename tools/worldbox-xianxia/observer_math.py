"""Offline reference: 4-view WorldBox 2.5D projection and honest source-resolution LOD."""
from dataclasses import dataclass

@dataclass(frozen=True)
class Camera:
    center_x: int
    center_y: int
    radius: int = 6
    quarter_turns: int = 0

    def __post_init__(self):
        if not 3 <= self.radius <= 9: raise ValueError("radius must be 3..9")
        if not 0 <= self.quarter_turns <= 3: raise ValueError("rotation must be 0..3")

    def project(self, x, y, tile_w=40.0):
        dx,dy=x-self.center_x,y-self.center_y
        if self.quarter_turns==1: dx,dy=dy,-dx
        elif self.quarter_turns==2: dx,dy=-dx,-dy
        elif self.quarter_turns==3: dx,dy=-dy,dx
        return (dx-dy)*tile_w/2.0,(dx+dy)*tile_w/4.0

    def in_view(self,x,y):
        return abs(x-self.center_x)<=self.radius and abs(y-self.center_y)<=self.radius

def zoom_lod(zoom, native_sizes=(32,64,96)):
    if zoom <= 0: raise ValueError("zoom must be positive")
    ideal=int(32*zoom+0.9999)
    return next((s for s in native_sizes if s>=ideal),native_sizes[-1])

def sampled_tile_count(radius):
    if radius < 0:raise ValueError("radius must be nonnegative")
    return (2*radius+1)**2
