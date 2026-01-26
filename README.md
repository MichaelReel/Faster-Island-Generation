# Faster Island Generation (In Godot 4.0 and greater)

## Introduction

After writing some terrain code in Godot 3.5.1 and porting it to Godot 4.0, I found the
custom object instanciation to be too slow to be practical. So this is another re-write
of [Terrain Scratch 2023](https://github.com/MichaelReel/Terrain_Scratch_2023) and 
[Island Generator for Godot 4](https://github.com/MichaelReel/Island-Generator-for-Godot-4).

The main attributes of this project are an attempt to avoid large arrays of custom classes,
and instead focus on using the build-in objects for data storage and manipulation.

:construction: Experimental, as always. :construction:

## Algorithm Flow

The island is built in stages, each stage requiring the data from the previous stages to perform various levels of enrichment.

Everything is controlled by the [TerrainManager](/island/generation/TerrainManager.gd) which creates each stage of generation, including passing parameters and references to the pre-requisite stages. Then it runs each stage in sequence.

## Stages

- [Grid](/island/generation/grid/notes.md)
- [Region](/island/generation/region/notes.md)
- [Lake](/island/generation/lakes/notes.md)
- [Height](/island/generation/height/notes.md)
- [River](/island/generation/rivers/notes.md)
- [Civil](/island/generation/civil/notes.md) (Roads + Towns)
- [Cliff](/island/generation/cliffs/notes.md)
- (Local) - I'm not satisfied with this step, so I Will probably remove
