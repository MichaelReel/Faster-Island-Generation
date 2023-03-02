# Faster Island Generation (In Godot 4.0 and greater)

## Introduction

After writing some terrain code in Godot 3.5.1 and porting it to Godot 4.0, I found the
custom object instanciation to be too slow to be practical. So this is another re-write
of [Terrain Scratch 2023](https://github.com/MichaelReel/Terrain_Scratch_2023) and 
[Island Generator for Godot 4](https://github.com/MichaelReel/Island-Generator-for-Godot-4).

The main attributes of this project are an attempt to avoid large arrays of custom classes,
and instead focus on using the build-in objects for data storage and manipulation.

:construction: Experimental, as always. :construction: