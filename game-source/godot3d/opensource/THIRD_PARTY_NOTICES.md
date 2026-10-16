# Canglan public 3D open-source notices

## Active: Godot Engine 4.4.1

Godot Engine source and runtime are released under MIT/Expat.
Copyright (c) 2014-present Godot Engine contributors; 2007-2014 Juan
Linietsky, Ariel Manzur. Full source/notice: https://godotengine.org/license/

## Active: Godot native FastNoiseLite

Used for reproducible terrain and ecological zones. Bundled in official
Godot 4.4.1; no separate addon download. Upstream FastNoiseLite MIT
source/notice: https://github.com/Auburn/FastNoiseLite/blob/master/LICENSE

## Active: Godot native SurfaceTool, ArrayMesh, MultiMesh, CharacterBody3D

No third party generator/addon is required at runtime. Their implementation
is part of the Godot MIT engine.

## Proposed open-source components NOT installed/imported

Terrain3D 1.0.2 (TokisanGames), MIT, Godot 4.4 compatible:
https://github.com/TokisanGames/Terrain3D ; on mobile, check platform
constraints and arm64 GDExtension/texture arrays before integrating.

Blender, GPL, for OFFLINE procedural GLB generation only:
https://www.blender.org/about/license/
The Blender executable and GPL addon code are NOT embedded in Android.

Kenney, Poly Haven and ambientCG CC0 art are SOURCES ONLY:
https://kenney.nl/support
https://polyhaven.com/license
https://docs.ambientcg.com/license/

No external GLB, textures, characters or copyrighted NPC artwork have yet
been installed in this new project. Prospective assets must carry exact
asset file SHA256, upstream URL, clear copyright/licence, version, QA/Android
performance evidence. Open source does not imply anonymous assets are safe.

### Engine MIT license

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
