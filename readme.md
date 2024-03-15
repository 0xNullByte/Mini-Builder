# Mini-Builder
####  Mini-Builder; Is a streamlined build system for C/C++ projects with the added capability of integrating hybrid ASM files. It depends on the Microsoft C++ toolset, utilizing MSVC, MASM, and LINK.exe. Within a single PowerShell file!
## Why? you have **Visual Studio IDE**!?
- It's 2024 now, and I still can't memorize the location of VS settings and configurations. There are so many configurations and settings, yet all you really need are MSVC (cl.exe), MASM (ml/64.exe), and LINK.exe. The complexity of VS is unbearable. And let's not even talk about how many times you have to "clean" your project to make it build successfully! The only thing I appreciate in VS is the debug tools; they're incredible. But there are plenty of external debug tools, so yeah, get me out of this hell! *`It's my own opinion.`*

## Features
* Hybrid C/C++ & ASM.
* Compile C and C++ files inside `src/include` folder recursively¹
* Compile ASM files inside `src/asm` folder recursively¹
* link libraries inside `src/lib` folder recursively¹
* Support x86-32 and x86-64 *you must setup the build-env for the specific arch [more info](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170#developer_command_prompt_shortcuts)*
* Clean build folder.

<sub>¹ It's mean all the files inside `src/include` or `src/asm` including even the files inside subdirectories. e.g: `/src/include/any/thing/player.cpp` or `/src/asm/any/thing/math_vec.asm` </sup>

## Getting Started
### Usage:

* using `Developer PowerShell`
  
  ```
  PS C:\project>builder.ps1 help
    Commands help:
        build       : compile and link cpp ONLEY.
        build asm   : compile and link cpp & asm.
        build flags : Compile with specific flags     ** make sure flags is the last argument **
                                                         ./builder.ps1 build flags /ZI /O2 ...
                                                         ./builder.ps1 build asm flags /ZI /O2 ...

        clean : clean build directory.
        help  : show this message.
  ```
### You have to consider only 3 rules:
  1. You cannot run the script without setting up your build environment before building! *Developer PowerShell/Command Prompt* [click for more info](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170)
  2. There is a template you must follow it. Look at this tree to make it clean:
       ```
      project
      ├── build/              <- All the output files.
      │   ├── obj/            <- Our objects files.
      │   └── main.exe        <- Our executable.
      └── src/
          ├── asm/            <- Our Assembly files.
          ├── include/        <- Our C++/C files source and headers.
          ├── lib/            <- Our lib files.
          ├── main.cpp        <- Our Entrypoint.
          └── builder.ps1     <- Our Mini-Builder.
       ```
     * C++/C files **MUST** end with `.cpp or .c` <sub>*header files can end with any extension, .h or .hpp or any other*</sub>
     * ASM files **MUST** end with `.asm`.
     * LIB files **MUST** end with `.lib`.

     logic usage example:
     ```
      project/
      ├── build/
      |       ── OUTPUT FOLDER ── 
      │   ├── obj/
      │   │   ├── m_vec.obj
      │   │   ├── player.obj 
      │   │   └── world.obj
      │   └── main.exe
      │
      └── src/
          |     ── INPUT FOLDER ──
          ├── asm/
          │   └── m_vec.asm
          ├── include/
          │   ├── player/
          │   │   ├── player.cpp
          │   │   └── player.hpp
          │   ├── world/
          │   │   ├── world.cpp
          │   │   └── world.hpp
          │   ├── game.cpp
          │   └── game.h
          ├── lib/
          │    └── window_eng.lib
          │
          ├── main.cpp       <- Our Entrypoint.
          └── builder.ps1    <- Our Mini-Builder.
     ```
    
  3. You cannot have C/C++/ASM files that **have the same NAME**!
     ```
     E.g:
       /src/asm/player.asm        -> going to produce `player.obj`
       /src/include/player.cpp    -> going to produce `player.obj`
                                   So which one going to link to the executable?
                                   unfortunately, our mini-builder not that smart.
                                   That's why it's called mini XD.
     
     * It's going to compile and link the the C/C++ obj producer file beacuse it's compiled after asm file*
     * Short: C/C++ obj going to overwrite ASM obj file *         
     ```    
     **Congratulations, you mastered Mini-Builder!**

     ## bonus
      * You can use `builder.ps1` to intract with your IDE/Code editor.
       For example here is a `.vscode/task.json` from VC to trigger build task `CTRL + SHIFT + B`.

        ```json
        {
            "version": "2.0.0",
            "tasks": [
                {
                    "label": "run builder",
                    "type": "shell",
                    "command": "./builder.ps1 build flags /O2",
                    "group": {
                        "kind": "build",
                        "isDefault": true
                    }
                }
                
            ]
        }
        ```
  


