@echo off

REM This script assumes that 'nasm' is in your path

cd os
echo | set /p x=Building BareMetal OS... 
call nasm kernel64.asm -o ..\kernel64.sys && (echo Success) || (echo Error!)
cd ..
pause