<#
    MIT License

    Copyright (c) 2024 0xNuLLByte

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

# Entrypoint
[Builder]::new($args) | Out-Null

# Builder Class.
class Builder{
    [System.Array] $cpp_src_files = (Get-ChildItem -Path src/include -Include *.cpp, *.c -Recurse | ForEach-Object { $_.FullName.Substring($_.FullName.IndexOf("src\"))})
    [System.Array] $cpp_src_lib   = (Get-ChildItem -Path src/lib -Filter *.lib -Recurse           | ForEach-Object { $_.FullName.Substring($_.FullName.IndexOf("src\"))})
    [System.Array] $asm_src_files = (Get-ChildItem -Path src/asm -Filter *.asm -Recurse           | ForEach-Object { $_.FullName.Substring($_.FullName.IndexOf("src\"))})
    
    [System.Array] $c_flags       = @("/c", "/EHsc", "/nologo")
    [string]       $arch          = $env:Platform
    
    [string]       $main_file     = "src/main.cpp"
    [string]       $header_folder = "src/include"
    [string]       $build_dir     = "build/"
    [string]       $out_obj_dir   = ($this.build_dir + "obj/")
    [string]       $output_file   = ($this.build_dir + "main.exe")

    Builder([System.Array]$commands){
        $this.check_env()
        $this.check_templete()
        $this.set_flags($commands)
        
        switch ($commands[0]) {
            "build" {
                if($commands[1] -eq "asm" -or ($commands[1] -eq "asm" -and $commands[2] -eq "flags"))
                {
                    if($commands[2].Length -gt 0 -and $commands[2] -ne "flags"){ $this.help_msg() }
                    $this.compile_asm()
                }
                elseif($commands[1].Length -gt 0 -and $commands[1] -ne "flags" ) { $this.help_msg() }
                
                $this.compile_cpp()
                $this.link()
            }
            "clean" {
                Get-ChildItem -Path $this.build_dir -File -Recurse | Where-Object { $_.Extension -notin @('.dll') } | Remove-Item -Force # Optional
                Write-Output "Cleaned successfully!"
            }
            Default {
                $this.help_msg()
            }
        }    
    }

    [void] compile_cpp(){
        # Compiling
        cl.exe $this.c_flags ("/Fd" + $this.build_dir) ("/Fo" + $this.out_obj_dir) /I $this.header_folder $this.cpp_src_files $this.main_file
        
        # Check if compiled process returned error code.
        if($LastExitCode -ne 0){
            # If so, then re-compile again, but this time show me the error output.
            cl.exe $this.c_flags ("/Fd" + $this.build_dir) ("/Fo" + $this.out_obj_dir) /I $this.header_folder $this.cpp_src_files $this.main_file | Out-Host
            Exit($LastExitCode)
        }
        Write-Host "[+] Compiled C++ succesfully!"
    }

    [void] compile_asm(){
        switch($this.arch){
            "x64" {
                ml64.exe /c ("/Fo" + $this.out_obj_dir) $this.asm_src_files
                if($LastExitCode -ne 0){
                    ml64.exe /c ("/Fo" + $this.out_obj_dir) $this.asm_src_files | Out-Host
                    Exit($LastExitCode)
                }
                Write-Host "[+] Compiled ASM64 succesfully!"
            }
            "x86" {
                ml.exe /c ("/Fo" + $this.out_obj_dir) $this.asm_src_files 
                if($LastExitCode -ne 0){
                    ml.exe /c ("/Fo" + $this.out_obj_dir) $this.asm_src_files
                    Exit($LastExitCode)
                }
                Write-Host "[+] Compiled ASM32 succesfully!"
            }
        }
    }

    [void] link(){
       link.exe ($this.out_obj_dir + "*.obj") ("/out:" + $this.output_file) $this.cpp_src_lib $this.c_flags

        if($LastExitCode -ne 0){
            link.exe ($this.out_obj_dir + "*.obj") ("/out:" + $this.output_file) $this.cpp_src_lib $this.c_flags | Out-Host
            Exit($LastExitCode)
        }
        Write-Host "[+] Linked succesfully!"
        Write-Host ("-" * 30) "`n[+] output:" $this.output_file
       
    }

    [void] check_env(){
        if(!$env:VCToolsVersion){
            Write-Host "[!] You must setup your build environment before build! [vcvarsall.bat]"
            Exit(1)
        }
    }

    [void] check_templete(){
        $dir = Get-ChildItem -Path . -Dir
        if(!($dir  -Join ", ").Contains("build, src")){
            Write-Host "[!] You're missing one of those folders : [ build, src ]"
            Exit(1)
        }

        $src_dirs   = (Get-ChildItem -Path src -Recurse | ForEach-Object { $_.FullName.Substring($_.FullName.IndexOf("src\"))}) 
        if(!($src_dirs  -Join ", ").Contains("src\asm, src\include, src\lib, src\main.cpp")){
            Write-Host "[!] You're missing one of those files : [ src\asm, src\include, src\lib, src\main.cpp ]"
            Exit(1)
        }
        
        $build_dirs = (Get-ChildItem -Path build -Recurse | ForEach-Object { $_.FullName.Substring($_.FullName.IndexOf("build\"))})
        if(!($build_dirs  -Join "").Contains("build\obj")){
            Write-Host "[!] You're missing one of those files : [ build\obj ]"
            Exit(1)
        }
    }

    [void] set_flags([System.Array]$commands){
        $flags_idx = 0
        foreach($c in $commands){
            $flags_idx++
            if($c -eq "flags"){
                foreach($i in $flags_idx..($commands.Length - 1)){
                    $this.c_flags += $commands[$i]
                }
            }
        }
    }

    [void] help_msg(){
        $help_command  = "Commands:                                                                                  `n`t"
        $help_command += "build       : Compile and link C/++ ONLEY.                                                 `n`t"
        $help_command += "build asm   : Compile and link C/++ & asm.                                                 `n`t"
        $help_command += "build flags : Compile with specific flags.     ** make sure flags is the last argument **  `n`t"
        $help_command += "                                                 ./builder.ps1 build flags /ZI /O2 ...     `n`t"
        $help_command += "                                                 ./builder.ps1 build asm flags /ZI /O2 ... `n`t"
        $help_command += "clean : Clean build directory.                                                             `n`t"
        $help_command += "help  : Show this message.                                                                     "
        Write-Host $help_command
        Exit(1)
    }
}

